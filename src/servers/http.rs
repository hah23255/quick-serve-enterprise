use log::{debug, info, error};

use bytes::Bytes;
use crate::servers::Protocol;
use crate::utils::validation;
use http_body_util::Full;

use hyper_util::rt::TokioIo;
use hyper::{Request, Response, StatusCode};
use hyper::server::conn::http1;
use hyper::service::service_fn;

use std::net::{IpAddr, SocketAddr};
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::Arc;

use super::Server;
use tokio::net::TcpListener;


// ENTERPRISE: Helper function to load custom error pages
async fn load_error_page(status_code: u16) -> Bytes {
    let error_page_path = format!("assets/error-pages/{}.html", status_code);
    match tokio::fs::read(&error_page_path).await {
        Ok(content) => Bytes::from(content),
        Err(_) => {
            // Fallback to basic error message if custom page not found
            Bytes::from(format!("Error {}: {}", status_code, match status_code {
                403 => "Forbidden",
                404 => "Not Found",
                500 => "Internal Server Error",
                _ => "Unknown Error"
            }))
        }
    }
}


async fn receive_request(req: Request<hyper::body::Incoming>, base_path: Arc<PathBuf>) -> Result<Response<Full<Bytes>>, hyper::Error> {

    // Remove the trailing slash from the path to avoid
    // Path treating it as absolute path and ignoring the base path
    let req_path = req.uri().path().strip_prefix('/').unwrap_or(req.uri().path());

    // UPSTREAM: Use the new validation function for security checks
    let file_path = match crate::utils::validation::validate_file_path(&base_path, req_path) {
        Ok(path) => path,
        Err(e) => {
            error!("Path validation failed for '{}': {}", req_path, e);
            // ENTERPRISE: Use custom error page
            let error_page = load_error_page(400).await;
            return Ok(Response::builder()
                .status(StatusCode::BAD_REQUEST)
                .header("Content-Type", "text/html; charset=utf-8")
                .body(Full::new(error_page))
                .unwrap());
        }
    };

    info!("Request path: {}", file_path.display());

    if !file_path.exists() {
        info!("File does not exist: {}", file_path.display());
        // ENTERPRISE: Custom 404 error page
        let error_page = load_error_page(404).await;
        return Ok(Response::builder()
            .status(StatusCode::NOT_FOUND)
            .header("Content-Type", "text/html; charset=utf-8")
            .body(Full::new(error_page))
            .unwrap());
    }

    // ENTERPRISE: Enhanced directory handling - try to serve index.html or return 403
    if file_path.is_dir() {
        info!("Directory access detected: {}", file_path.display());

        // Try to serve index.html from the directory
        let index_path = file_path.join("index.html");
        if index_path.exists() && index_path.is_file() {
            info!("Serving index.html from directory");
            match tokio::fs::read(&index_path).await {
                Ok(content) => {
                    return Ok(Response::builder()
                        .header("Content-Type", "text/html; charset=utf-8")
                        .body(Full::new(Bytes::from(content)))
                        .unwrap());
                },
                Err(e) => {
                    error!("Error reading index.html: {}", e);
                    let error_page = load_error_page(500).await;
                    return Ok(Response::builder()
                        .status(StatusCode::INTERNAL_SERVER_ERROR)
                        .header("Content-Type", "text/html; charset=utf-8")
                        .body(Full::new(error_page))
                        .unwrap());
                }
            }
        }

        // ENTERPRISE: No index.html found, return 403 Forbidden (not BAD_REQUEST)
        info!("No index.html in directory, returning 403");
        let error_page = load_error_page(403).await;
        return Ok(Response::builder()
            .status(StatusCode::FORBIDDEN)
            .header("Content-Type", "text/html; charset=utf-8")
            .body(Full::new(error_page))
            .unwrap());
    }

    // Regular file serving with ENTERPRISE Content-Type detection
    match tokio::fs::read(&file_path).await {
        Ok(file_content) => {
            // ENTERPRISE: Detect content type based on file extension
            let content_type = match file_path.extension().and_then(|e| e.to_str()) {
                Some("html") => "text/html; charset=utf-8",
                Some("css") => "text/css; charset=utf-8",
                Some("js") => "application/javascript; charset=utf-8",
                Some("json") => "application/json; charset=utf-8",
                Some("png") => "image/png",
                Some("jpg") | Some("jpeg") => "image/jpeg",
                Some("gif") => "image/gif",
                Some("svg") => "image/svg+xml",
                Some("txt") => "text/plain; charset=utf-8",
                _ => "application/octet-stream"
            };

            info!("Successfully served file: {} ({} bytes)", file_path.display(), file_content.len());
            Ok(Response::builder()
                .header("Content-Type", content_type)
                .body(Full::new(Bytes::from(file_content)))
                .unwrap())
        }
        Err(e) => {
            error!("Failed to read file {}: {}", file_path.display(), e);
            // ENTERPRISE: Custom 500 error page
            let error_page = load_error_page(500).await;
            Ok(Response::builder()
                .status(StatusCode::INTERNAL_SERVER_ERROR)
                .header("Content-Type", "text/html; charset=utf-8")
                .body(Full::new(error_page))
                .unwrap())
        }
    }
}


pub trait HTTPRunner {
    fn new(path: PathBuf, bind_ip: String, port: u16) -> Result<Self, crate::QuickServeError> where Self: Sized;
    fn runner(&self);
}

impl HTTPRunner for Server {
    fn new(path: PathBuf, bind_ip: String, port: u16) -> Result<Self, crate::QuickServeError> {
        let mut s = Server::default();

        // UPSTREAM: Validate inputs with proper error handling
        validation::validate_path(&path)?;
        validation::validate_ip_port(&bind_ip, port)?;

        s.path = Arc::new(path.clone()); // Make a clone of the path and store it in the Server struct
        s.bind_address = IpAddr::from_str(&bind_ip)
            .map_err(|e| crate::QuickServeError::validation(format!("Invalid IP address '{}': {}", bind_ip, e)))?;
        s.port = port;

        s.protocol = Protocol::Http;
        HTTPRunner::runner(&s);
        Ok(s)
    }

    fn runner(&self) {
        let mut receiver = self.sender.subscribe();

        let bind_address = self.bind_address;
        let port = self.port;
        let path = self.path.clone();

        tokio::spawn(async move {
            loop {
                debug!("HTTP runner started. Waiting command to connect...");

                let m = match receiver.recv().await {
                    Ok(msg) => msg,
                    Err(e) => {
                        error!("Failed to receive message in HTTP runner: {}", e);
                        break;
                    }
                };
                debug!("Message received");

                if m.connect {
                    info!("Starting HTTP server on {}:{}", bind_address, port);

                    let tsk = tokio::spawn(async move {
                        let socket_addr = SocketAddr::new(bind_address, port);

                        let listener = match TcpListener::bind(socket_addr).await {
                            Ok(listener) => {
                                info!("HTTP server listening on {}", socket_addr);
                                listener
                            }
                            Err(e) => {
                                error!("Failed to bind HTTP server to {}: {}", socket_addr, e);
                                return;
                            }
                        };

                        loop {
                            match listener.accept().await {
                                Ok((stream, addr)) => {
                                    debug!("New HTTP connection from {}", addr);
                                    let io = TokioIo::new(stream);
                                    let path_clone = path.clone();

                                    tokio::spawn(async move {
                                        if let Err(err) = http1::Builder::new()
                                            .serve_connection(io, service_fn(move |req| receive_request(req, path_clone.clone())))
                                            .await
                                        {
                                            error!("Error serving HTTP connection from {}: {:?}", addr, err);
                                        }
                                    });
                                }
                                Err(e) => {
                                    error!("Failed to accept HTTP connection: {}", e);
                                    // Continue accepting other connections
                                }
                            }
                        }
                    });

                    // Wait for stop command
                    match receiver.recv().await {
                        Ok(_) => {
                            info!("Stop command received, shutting down HTTP server");
                            tsk.abort();
                            debug!("HTTP server stopped");
                            break;
                        }
                        Err(e) => {
                            error!("Failed to receive stop command: {}", e);
                            tsk.abort();
                            break;
                        }
                    }
                }
            }
        });
    }
}


/////////////////////////////////////////////////////////////////////////////////////
//                                        TESTS                                    //
/////////////////////////////////////////////////////////////////////////////////////
#[cfg(test)]
mod tests {
    use crate::tests::common::tests::*;
    use crate::servers::Protocol;

    #[test]
    fn test_http_file_download_success() {
        let proto = Protocol::Http;
        let port = 8079u16;
        let file_in = "data.bin";
        let file_out = "/tmp/data-out-http.bin";
        let dl_cmd = format!("wget -t2 -T1 {}://127.0.0.1:{}/{} -O {}", proto.to_string(), port, file_in, file_out);

        test_server_e2e(proto, port, dl_cmd, file_in, file_out);
    }

    #[test]
    fn test_file_not_found() {
        let proto = Protocol::Http;
        let port = 8080u16;
        let file_in = "data.bin";
        let nonexistent_file = "nonexistent.bin";
        let file_out = "/tmp/data-out-http-404.bin";
        let dl_cmd = format!("wget -t1 -T1 {}://127.0.0.1:{}/{} -O {} 2>&1 || true",
            proto.to_string(), port, nonexistent_file, file_out);

        let result = std::panic::catch_unwind(|| {
            test_server_e2e(proto, port, dl_cmd.clone(), file_in, file_out);
        });
        assert!(result.is_err(), "Expected failure for non-existent file");
    }

    #[test]
    fn test_path_is_directory() {
        let proto = Protocol::Http;
        let port = 8081u16;
        let file_in = "data.bin";
        let file_out = "/tmp/data-out-http-dir.bin";
        let dl_cmd = format!("wget -t1 -T1 {}://127.0.0.1:{}/ -O {} 2>&1 || true",
            proto.to_string(), port, file_out);

        let result = std::panic::catch_unwind(|| {
            test_server_e2e(proto, port, dl_cmd.clone(), file_in, file_out);
        });
        assert!(result.is_err(), "Expected failure for directory path");
    }

    #[test]
    fn test_path_traversal_blocked() {
        let proto = Protocol::Http;
        let port = 8082u16;
        let file_in = "data.bin";
        let file_out = "/tmp/data-out-http-traversal.bin";
        let dl_cmd = format!("wget -t1 -T1 {}://127.0.0.1:{}/../../etc/passwd -O {} 2>&1 || true",
            proto.to_string(), port, file_out);

        let result = std::panic::catch_unwind(|| {
            test_server_e2e(proto, port, dl_cmd.clone(), file_in, file_out);
        });
        assert!(result.is_err(), "Expected failure for path traversal attempt");
    }
}

use log::{debug, info};

use async_trait::async_trait;
use bytes::Bytes;
use crate::servers::Protocol;
use crate::utils::validation;
use http_body_util::Full;

use hyper_util::rt::TokioIo;
use hyper::{Request, Response};
use hyper::server::conn::http1;
use hyper::service::service_fn;

use std::net::{IpAddr, SocketAddr};
use std::path::PathBuf;
use std::str::FromStr;
use std::sync::Arc;

use super::Server;
use tokio::net::TcpListener;


// Helper function to load error page
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

    let file_path = base_path.join(req_path);

    info!("Request path: {}", file_path.display());

    if !file_path.exists() {
        info!("File does not exist: {}", file_path.display());
        let error_page = load_error_page(404).await;
        return Ok(Response::builder()
            .status(404)
            .header("Content-Type", "text/html; charset=utf-8")
            .body(Full::new(error_page))
            .unwrap());
    }

    // FIX: Handle directory access - try to serve index.html or return 403
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
                    info!("Error reading index.html: {}", e);
                    let error_page = load_error_page(500).await;
                    return Ok(Response::builder()
                        .status(500)
                        .header("Content-Type", "text/html; charset=utf-8")
                        .body(Full::new(error_page))
                        .unwrap());
                }
            }
        }

        // No index.html found, return 403 Forbidden
        info!("No index.html in directory, returning 403");
        let error_page = load_error_page(403).await;
        return Ok(Response::builder()
            .status(403)
            .header("Content-Type", "text/html; charset=utf-8")
            .body(Full::new(error_page))
            .unwrap());
    }

    // Handle regular file with proper error handling
    match tokio::fs::read(&file_path).await {
        Ok(content) => {
            // Detect content type based on file extension
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

            Ok(Response::builder()
                .header("Content-Type", content_type)
                .body(Full::new(Bytes::from(content)))
                .unwrap())
        },
        Err(e) => {
            info!("Error reading file {}: {}", file_path.display(), e);
            let error_page = load_error_page(500).await;
            Ok(Response::builder()
                .status(500)
                .header("Content-Type", "text/html; charset=utf-8")
                .body(Full::new(error_page))
                .unwrap())
        }
    }
}


#[async_trait]
pub trait HTTPRunner {
    fn new(path: PathBuf, bind_ip: String, port: u16) -> Self;
    fn runner(&self);
}

#[async_trait]
impl HTTPRunner for Server {
    fn new(path: PathBuf, bind_ip: String, port: u16) -> Self {
        let mut s = Server::default();

        validation::validate_path(&path).expect("Invalid path");
        validation::validate_ip_port(&bind_ip, port).expect("Invalid bind IP");

        s.path = Arc::new(path.clone()); // Make a clone of the path and store it in the Server struct
        s.bind_address = IpAddr::from_str(&bind_ip).expect("Invalid IP address");
        s.port = port;

        s.protocol = Protocol::Http;
        HTTPRunner::runner(&s);
        s
    }

    fn runner(&self) {
        let mut receiver = self.sender.subscribe();

        let bind_address = self.bind_address;
        let port = self.port;
        let path = self.path.clone();
        
        tokio::spawn(async move {
            loop {
                debug!("Runner started. Waiting command to connect...");
                let m = receiver.recv().await.unwrap();
                debug!("Message received");

                if m.connect {
                    info!("Connecting...");
                    // Create a SocketAddr from the IpAddr and port

                    let tsk = tokio::spawn(async move {
                        let socket_addr = SocketAddr::new(bind_address, port);
                        let listener = TcpListener::bind(socket_addr).await.unwrap();

                        loop {
                            let (stream, _) = listener.accept().await.unwrap();
                            let io = TokioIo::new(stream);
                            let path_clone = path.clone();

                            info!("Serving...");
                            if let Err(err) = http1::Builder::new()
                                .serve_connection(io, service_fn(move |req| receive_request(req, path_clone.clone())))
                                .await
                            {
                                println!("Error serving connection: {:?}", err);
                            }
                        }
                    });

                    let _ = receiver.recv().await.unwrap();
                    tsk.abort();
                    debug!("HTTP server stopped");
                    break;
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
    fn e2e() {
        let proto = Protocol::Http;
        let port = 8079u16;
        let file_in = "data.bin";
        let file_out = "/tmp/data-out-http.bin";
        let dl_cmd = format!("wget -t2 -T1 {}://127.0.0.1:{}/{} -O {}", proto.to_string(), port, file_in, file_out);

        test_server_e2e(proto, port, dl_cmd, file_in, file_out);
    }
}

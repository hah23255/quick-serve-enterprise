# Bug Report: HTTP Server Panic on Directory Access

## Summary
The HTTP server crashes with a panic when attempting to access a directory path instead of a file, due to improper error handling in `src/servers/http.rs:41`.

## Severity
**HIGH** - Server crashes and becomes unavailable on any directory access (including root path `/`)

## Environment
- **Version**: quick-serve v0.3.1
- **Platform**: Android (Termux) on ARM64
- **OS**: Linux 6.6.57-android15-8-31566393
- **Build**: Release mode, optimized
- **Rust Version**: (built with rustc from Termux)

## Bug Details

### Location
**File**: `src/servers/http.rs`
**Line**: 41
**Function**: `receive_request()`

### Code
```rust
let file_content = tokio::fs::read(file_path).await.unwrap();
```

### Root Cause
The code calls `.unwrap()` on `tokio::fs::read()` without handling the case where the path is a directory. When `tokio::fs::read()` receives a directory path, it returns an error (`Os { code: 21, kind: IsADirectory, message: "Is a directory" }`), which causes the unwrap to panic.

## Reproduction Steps

1. Start quick-serve HTTP server:
```bash
quick-serve --headless --http=8080 --serve-dir=/path/to/directory/
```

2. Access root path or any directory:
```bash
curl http://localhost:8080/
# OR
curl http://localhost:8080/some-directory/
```

3. **Result**: Server crashes with panic:
```
thread 'tokio-runtime-worker' panicked at src/servers/http.rs:41:57:
called `Result::unwrap()` on an `Err` value: Os { code: 21, kind: IsADirectory, message: "Is a directory" }
```

## Expected Behavior
Server should:
1. Detect directory access
2. Either:
   - Serve directory listing (index.html-style)
   - Serve index.html if present in directory
   - Return 403 Forbidden with appropriate message
   - Return 404 Not Found
3. **NOT crash**

## Actual Behavior
Server panics and terminates, requiring manual restart.

## Impact
- **User Experience**: Crashes on common usage pattern (accessing root `/`)
- **Availability**: Server becomes unavailable after first directory access
- **Security**: Potential DoS vector (intentional directory access to crash server)

## Error Log
```
[INFO] quick_serve::servers::http: Serving...
[INFO] quick_serve::servers::http: Request path: /data/data/com.termux/files/home/tmp/test-serve/
thread 'tokio-runtime-worker' panicked at src/servers/http.rs:41:57:
called `Result::unwrap()` on an `Err` value: Os { code: 21, kind: IsADirectory, message: "Is a directory" }
note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
```

## Proposed Fix

### Option 1: Check if path is directory before reading
```rust
async fn receive_request(req: Request<hyper::body::Incoming>, base_path: Arc<PathBuf>) -> Result<Response<Full<Bytes>>, hyper::Error> {
    let req_path = req.uri().path().strip_prefix('/').unwrap_or(req.uri().path());
    let file_path = base_path.join(req_path);

    info!("Request path: {}", file_path.display());

    if !file_path.exists() {
        info!("File does not exist: {}", file_path.display());
        return Ok(Response::builder()
            .status(404)
            .body(Full::new(Bytes::from("File not found")))
            .unwrap());
    }

    // FIX: Check if path is a directory
    if file_path.is_dir() {
        // Try to serve index.html
        let index_path = file_path.join("index.html");
        if index_path.exists() && index_path.is_file() {
            let file_content = tokio::fs::read(index_path).await
                .map_err(|e| {
                    eprintln!("Error reading index.html: {}", e);
                    hyper::Error::from(std::io::Error::new(std::io::ErrorKind::Other, e))
                })?;
            return Ok(Response::new(Full::new(Bytes::from(file_content))));
        }

        // No index.html, return directory listing or 403
        return Ok(Response::builder()
            .status(403)
            .body(Full::new(Bytes::from("Directory listing not supported")))
            .unwrap());
    }

    // Read file with proper error handling
    let file_content = tokio::fs::read(file_path).await
        .map_err(|e| {
            eprintln!("Error reading file: {}", e);
            hyper::Error::from(std::io::Error::new(std::io::ErrorKind::Other, e))
        })?;

    Ok(Response::new(Full::new(Bytes::from(file_content))))
}
```

### Option 2: Use match for error handling
```rust
let file_content = match tokio::fs::read(file_path.clone()).await {
    Ok(content) => content,
    Err(e) if e.kind() == std::io::ErrorKind::IsADirectory => {
        // Handle directory access
        return Ok(Response::builder()
            .status(403)
            .body(Full::new(Bytes::from("Directory access not allowed")))
            .unwrap());
    },
    Err(e) => {
        eprintln!("Error reading file: {}", e);
        return Ok(Response::builder()
            .status(500)
            .body(Full::new(Bytes::from("Internal server error")))
            .unwrap());
    }
};
```

## Workaround (for users)
Always access specific files, never directories:
```bash
# ❌ Don't do this (crashes):
curl http://localhost:8080/

# ✅ Do this instead:
curl http://localhost:8080/index.html
curl http://localhost:8080/file.txt
```

## Additional Notes
- This affects all HTTP server instances
- Bug is present in both `--headless` and GUI modes
- Other protocols (FTP, TFTP, DHCP) not affected
- Issue occurs regardless of bind IP (127.0.0.1 or 0.0.0.0)
- File serving works correctly when files are accessed directly

## Testing Recommendations
After fix, verify:
1. ✅ Accessing files works: `curl http://localhost:8080/file.txt`
2. ✅ Accessing root doesn't crash: `curl http://localhost:8080/`
3. ✅ Accessing subdirectories doesn't crash: `curl http://localhost:8080/subdir/`
4. ✅ 404 for non-existent files: `curl http://localhost:8080/nonexistent`
5. ✅ Proper HTTP status codes returned
6. ✅ Server remains stable under load

## References
- Repository: https://github.com/joaofl/quick-serve
- Error location: src/servers/http.rs:41:57
- Rust std::io::ErrorKind: https://doc.rust-lang.org/std/io/enum.ErrorKind.html

---
**Reported by**: Integration testing in Termux Android environment
**Date**: 2025-10-19
**Build**: Release v0.3.1 from source (commit: main branch)

use crate::frb_generated::StreamSink;
use once_cell::sync::Lazy;
use std::sync::{Arc, Mutex};
use std::thread;
use zilpay::background::Background;

pub struct BackgroundService {
    running: Arc<Mutex<bool>>,
    message_queue: Arc<Mutex<Vec<String>>>,
    // app: Option<Arc<Mutex<Background>>>,
}

impl Default for BackgroundService {
    fn default() -> Self {
        Self::new()
    }
}

impl BackgroundService {
    pub fn new() -> Self {
        BackgroundService {
            running: Arc::new(Mutex::new(false)),
            message_queue: Arc::new(Mutex::new(Vec::new())),
            // app: None,
        }
    }

    pub fn start(&self, sink: StreamSink<String>) {
        let running = Arc::clone(&self.running);
        let queue = Arc::clone(&self.message_queue);

        *running.lock().unwrap() = true;

        thread::spawn(move || {
            while *running.lock().unwrap() {
                {
                    let mut queue = queue.lock().unwrap();
                    while let Some(message) = queue.pop() {
                        let result = format!("Processed: {}", message);
                        sink.add(result).unwrap();
                    }
                }
                thread::sleep(std::time::Duration::from_millis(100));
            }
        });
    }

    pub fn stop(&self) {
        *self.running.lock().unwrap() = false;
    }

    pub fn send_message(&self, message: String) {
        self.message_queue.lock().unwrap().push(message);
    }
}

pub static BACKGROUND_SERVICE: Lazy<Mutex<BackgroundService>> =
    Lazy::new(|| Mutex::new(BackgroundService::new()));

pub fn start_background_service(sink: StreamSink<String>) -> Result<(), String> {
    let service = BACKGROUND_SERVICE.lock().map_err(|e| e.to_string())?;
    service.start(sink);
    Ok(())
}

pub fn stop_background_service() -> Result<(), String> {
    let service = BACKGROUND_SERVICE.lock().map_err(|e| e.to_string())?;
    service.stop();
    Ok(())
}

pub fn send_message_to_service(message: String) -> Result<(), String> {
    let service = BACKGROUND_SERVICE.lock().map_err(|e| e.to_string())?;
    service.send_message(message);
    Ok(())
}

pub trait LocalStorage {
    fn set(&self, key: String, value: String) -> Result<(), String>;
    fn get(&self, key: String) -> Option<String>;
    fn rm(&self, key: String) -> Result<(), String>;
}

pub struct LocalStorageImpl {
    storage: zilpay::storage::LocalStorage,
}

impl LocalStorageImpl {
    pub fn new(path_dir: String) -> Result<Self, String> {
        let storage = zilpay::storage::LocalStorage::from(&path_dir).map_err(|e| e.to_string())?;
        Ok(Self { storage })
    }
}

impl LocalStorage for LocalStorageImpl {
    fn set(&self, key: String, value: String) -> Result<(), String> {
        self.storage
            .set(key.as_bytes(), value.as_bytes())
            .map_err(|e| e.to_string())?;
        self.storage.flush().map_err(|e| e.to_string())?;
        Ok(())
    }

    fn get(&self, key: String) -> Option<String> {
        self.storage
            .get(key.as_bytes())
            .ok()
            .and_then(|bytes| String::from_utf8(bytes).ok())
    }

    fn rm(&self, key: String) -> Result<(), String> {
        self.storage
            .remove(key.as_bytes())
            .map_err(|e| e.to_string())?;
        self.storage.flush().map_err(|e| e.to_string())?;
        Ok(())
    }
}

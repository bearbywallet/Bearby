import { createDecipheriv } from "crypto";

// Зашифрованные данные (JSON)
const encryptedData = {
  "iv": "6cf8e928391162149df8745a1b8e1a6c",
  "cipher": "lcX55T27+GCnuMDUVccdKwJQn624cWWt0uWWDUNYyTJE+d8QZLTyXEAeUfTzF6d3RiY8dQhppSquYigFhUc3mX63GOhWUvw/vFd4wZM77tQ="
};

// Ключ должен быть 32 байта (для AES-256), в HEX-формате
const keyHex = "c49b41812af9244cfafe08d07337e5dab9f23cca5ddc88ba00072289f1430f2d";
const key = Buffer.from(keyHex, "hex");

// Преобразуем iv из HEX в Buffer
const iv = Buffer.from(encryptedData.iv, "hex");

try {
  // Создаем объект для расшифрования
  const decipher = createDecipheriv("aes-256-cbc", key, iv);
  
  // Декодируем зашифрованный текст из Base64 и расшифровываем
  const encryptedBuffer = Buffer.from(encryptedData.cipher, "base64");
  let decrypted = decipher.update(encryptedBuffer);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  
  console.log("Расшифрованный текст:");
  console.log(decrypted.toString("utf8"));
} catch (err) {
  console.error("Ошибка при расшифровке:", err.message);
}

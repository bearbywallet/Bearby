const TAG_APDU: u8 = 0x05;

// ── HID framing ──

pub const HID_PACKET_SIZE: usize = 64;
pub const LEDGER_CHANNEL: u16 = 0x0001;

/// Split an APDU into 64-byte HID packets.
pub fn wrap_hid_apdu(channel: u16, apdu: &[u8], packet_size: usize) -> Vec<Vec<u8>> {
    let mut packets = Vec::new();
    let mut offset = 0usize;
    let mut sequence: u16 = 0;

    // First packet: channel(2) + tag(1) + seq(2) + len(2) = 7 byte header
    {
        let mut pkt = Vec::with_capacity(packet_size);
        pkt.push((channel >> 8) as u8);
        pkt.push((channel & 0xff) as u8);
        pkt.push(TAG_APDU);
        pkt.push((sequence >> 8) as u8);
        pkt.push((sequence & 0xff) as u8);
        sequence += 1;
        pkt.push((apdu.len() >> 8) as u8);
        pkt.push((apdu.len() & 0xff) as u8);

        let block_size = (apdu.len() - offset).min(packet_size - 7);
        pkt.extend_from_slice(&apdu[offset..offset + block_size]);
        offset += block_size;

        // Zero-pad to packet_size
        pkt.resize(packet_size, 0);
        packets.push(pkt);
    }

    // Subsequent packets: channel(2) + tag(1) + seq(2) = 5 byte header
    while offset < apdu.len() {
        let mut pkt = Vec::with_capacity(packet_size);
        pkt.push((channel >> 8) as u8);
        pkt.push((channel & 0xff) as u8);
        pkt.push(TAG_APDU);
        pkt.push((sequence >> 8) as u8);
        pkt.push((sequence & 0xff) as u8);
        sequence += 1;

        let block_size = (apdu.len() - offset).min(packet_size - 5);
        pkt.extend_from_slice(&apdu[offset..offset + block_size]);
        offset += block_size;

        pkt.resize(packet_size, 0);
        packets.push(pkt);
    }

    packets
}

/// Reassemble response from HID packets into a single APDU response.
pub fn unwrap_hid_response(channel: u16, data: &[u8], packet_size: usize) -> Option<Vec<u8>> {
    if data.len() < 7 {
        return None;
    }

    let mut offset = 0usize;
    let mut sequence: u16 = 0;

    // Validate first packet header
    if data[offset] != (channel >> 8) as u8 {
        return None;
    }
    offset += 1;
    if data[offset] != (channel & 0xff) as u8 {
        return None;
    }
    offset += 1;
    if data[offset] != TAG_APDU {
        return None;
    }
    offset += 1;
    if data[offset] != 0x00 || data[offset + 1] != 0x00 {
        return None;
    }
    offset += 2;

    let response_length =
        ((data[offset] as usize) << 8) | (data[offset + 1] as usize);
    offset += 2;

    if response_length == 0 {
        return Some(Vec::new());
    }

    let mut response = Vec::with_capacity(response_length);

    let block_size = (response_length).min(packet_size - 7).min(data.len() - offset);
    response.extend_from_slice(&data[offset..offset + block_size]);
    offset += block_size;

    // Skip padding of first packet
    let first_packet_end = ((offset - 1) / packet_size + 1) * packet_size;
    offset = first_packet_end;

    // Subsequent packets
    while response.len() < response_length {
        if offset >= data.len() {
            return None;
        }

        sequence += 1;

        if data[offset] != (channel >> 8) as u8 {
            return None;
        }
        offset += 1;
        if data[offset] != (channel & 0xff) as u8 {
            return None;
        }
        offset += 1;
        if data[offset] != TAG_APDU {
            return None;
        }
        offset += 1;
        if data[offset] != (sequence >> 8) as u8 {
            return None;
        }
        offset += 1;
        if data[offset] != (sequence & 0xff) as u8 {
            return None;
        }
        offset += 1;

        let block_size = (response_length - response.len())
            .min(packet_size - 5)
            .min(data.len() - offset);
        response.extend_from_slice(&data[offset..offset + block_size]);
        offset += block_size;

        // Skip padding
        let packet_end = ((offset - 1) / packet_size + 1) * packet_size;
        offset = packet_end;
    }

    if response.len() == response_length {
        Some(response)
    } else {
        None
    }
}

// ── BLE framing ──

/// Split an APDU into BLE chunks based on MTU size.
pub fn wrap_ble_apdu(apdu: &[u8], mtu: usize) -> Vec<Vec<u8>> {
    let first_payload_size = mtu - 5; // tag(1) + seq(2) + len(2) = 5
    let subsequent_payload_size = mtu - 3; // tag(1) + seq(2) = 3
    let mut chunks = Vec::new();
    let mut offset = 0usize;
    let mut sequence: u16 = 0;

    while offset < apdu.len() {
        let is_first = sequence == 0;
        let payload_size = if is_first {
            first_payload_size
        } else {
            subsequent_payload_size
        };
        let chunk_size = (apdu.len() - offset).min(payload_size);

        let header_size = if is_first { 5 } else { 3 };
        let mut chunk = Vec::with_capacity(header_size + chunk_size);
        chunk.push(TAG_APDU);
        chunk.push((sequence >> 8) as u8);
        chunk.push((sequence & 0xff) as u8);
        if is_first {
            chunk.push((apdu.len() >> 8) as u8);
            chunk.push((apdu.len() & 0xff) as u8);
        }
        chunk.extend_from_slice(&apdu[offset..offset + chunk_size]);

        chunks.push(chunk);
        offset += chunk_size;
        sequence += 1;
    }

    chunks
}

/// State for BLE response reassembly across notifications.
pub struct BleReceiveState {
    pub expected_index: u16,
    pub expected_length: usize,
    pub data: Vec<u8>,
}

impl BleReceiveState {
    pub fn new() -> Self {
        BleReceiveState {
            expected_index: 0,
            expected_length: 0,
            data: Vec::new(),
        }
    }

    pub fn reset(&mut self) {
        self.expected_index = 0;
        self.expected_length = 0;
        self.data.clear();
    }
}

/// Process a single BLE notification chunk. Returns `Some(complete_apdu)` when all chunks received.
pub fn unwrap_ble_chunk(chunk: &[u8], state: &mut BleReceiveState) -> Result<Option<Vec<u8>>, String> {
    if chunk.is_empty() || chunk[0] != TAG_APDU {
        return Ok(None);
    }

    if chunk.len() < 3 {
        return Err("BLE chunk too short".to_string());
    }

    let chunk_index = ((chunk[1] as u16) << 8) | (chunk[2] as u16);

    if chunk_index != state.expected_index {
        return Err(format!(
            "Expected sequence {}, got {}",
            state.expected_index, chunk_index
        ));
    }

    if chunk_index == 0 {
        // First chunk: has length field
        if chunk.len() < 5 {
            return Err("First BLE chunk too short for length".to_string());
        }
        state.expected_length = ((chunk[3] as usize) << 8) | (chunk[4] as usize);
        state.data.clear();
        state.data.extend_from_slice(&chunk[5..]);
    } else {
        state.data.extend_from_slice(&chunk[3..]);
    }

    state.expected_index += 1;

    if state.data.len() > state.expected_length {
        return Err(format!(
            "Expected {} bytes, got {}",
            state.expected_length,
            state.data.len()
        ));
    }

    if state.data.len() == state.expected_length {
        let result = state.data[..state.expected_length].to_vec();
        state.reset();
        Ok(Some(result))
    } else {
        Ok(None)
    }
}

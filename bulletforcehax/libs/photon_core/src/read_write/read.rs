use byteorder::{BigEndian, ReadBytesExt};
use std::collections::HashMap;
use std::io::{Cursor, Read};

use super::super::*;

pub fn read_debug_string<'a>(c: &mut Cursor<&'a [u8]>) -> PhotonReadResult<Option<&'a str>> {
    match read_value(c)? {
        ProtocolValue::Null() => Ok(None),
        ProtocolValue::String(string) => Ok(Some(string)),
        _ => Err(PhotonReadError::InvalidDebugStringType),
    }
}

pub fn read_value<'a>(c: &mut Cursor<&'a [u8]>) -> PhotonReadResult<ProtocolValue<'a>> {
    let protocol_type = c.read_u8()?;
    read_value_of_type(c, protocol_type)
}

pub fn read_value_of_type<'a>(c: &mut Cursor<&'a [u8]>, protocol_type: u8) -> PhotonReadResult<ProtocolValue<'a>> {
    match protocol_type {
        42 => Ok(ProtocolValue::Null()),
        68 => Err(PhotonReadError::UnimplementedProtocolValueType(ProtocolValue::Dictionary)),
        97 => {
            let len = c.read_u16::<BigEndian>()? as usize;
            let mut vec = Vec::new();
            for _ in 0..len {
                let len = c.read_u16::<BigEndian>()? as usize;
                let pos = c.position() as usize;
                let return_slice = &(*c.get_ref())[pos..pos + len];
                c.set_position((pos + len) as u64);
                let str_slice = std::str::from_utf8(return_slice)?;
                vec.push(str_slice);
            }
            Ok(ProtocolValue::StringArray(vec))
        }
        98 => Ok(ProtocolValue::Byte(c.read_u8()?)),
        99 => {
            let id = c.read_u8()?;
            let len = c.read_u16::<BigEndian>()?;
            Ok(ProtocolValue::Custom(match id {
                // note: should change these len checks with asserts
                b'W' if len == 8 => Ok(CustomType::Vector2(c.read_f32::<BigEndian>()?, c.read_f32::<BigEndian>()?)),
                b'V' if len == 12 => Ok(CustomType::Vector3(
                    c.read_f32::<BigEndian>()?,
                    c.read_f32::<BigEndian>()?,
                    c.read_f32::<BigEndian>()?,
                )),
                b'Q' if len == 16 => Ok(CustomType::Quaternion(
                    c.read_f32::<BigEndian>()?,
                    c.read_f32::<BigEndian>()?,
                    c.read_f32::<BigEndian>()?,
                    c.read_f32::<BigEndian>()?,
                )),
                b'P' if len == 4 => Ok(CustomType::Player(c.read_i32::<BigEndian>()?)),
                b'W' | b'V' | b'Q' | b'P' => Err(PhotonReadError::CustomTypeInvalidLength),
                _ => {
                    let mut data = vec![0; len as usize];
                    c.read_exact(data.as_mut_slice())?;
                    Ok(CustomType::Custom { id, data })
                }
            }?))
        }
        100 => Ok(ProtocolValue::Double(c.read_f64::<BigEndian>()?)),
        101 => Err(PhotonReadError::UnimplementedProtocolValueType(ProtocolValue::EventData)),
        102 => Ok(ProtocolValue::Float(c.read_f32::<BigEndian>()?)),
        104 => Ok(ProtocolValue::Hashtable(read_hash_table(c)?)),
        105 => Ok(ProtocolValue::Integer(c.read_i32::<BigEndian>()?)),
        107 => Ok(ProtocolValue::Short(c.read_i16::<BigEndian>()?)),
        108 => Ok(ProtocolValue::Long(c.read_i64::<BigEndian>()?)),
        110 => {
            let len = c.read_i32::<BigEndian>()? as usize;
            let mut vec = Vec::new();
            for _ in 0..len {
                vec.push(c.read_i32::<BigEndian>()?);
            }
            Ok(ProtocolValue::IntegerArray(vec))
        }
        111 => Ok(ProtocolValue::Bool(c.read_u8()? != 0)),
        112 => Err(PhotonReadError::UnimplementedProtocolValueType(ProtocolValue::OperationResponse)),
        113 => Err(PhotonReadError::UnimplementedProtocolValueType(ProtocolValue::OperationRequest)),
        115 => {
            let len = c.read_u16::<BigEndian>()? as usize;
            let pos = c.position() as usize;

            let return_slice = &(*c.get_ref())[pos..pos + len];
            c.set_position((pos + len) as u64);
            let str_slice = std::str::from_utf8(return_slice)?;
            Ok(ProtocolValue::String(str_slice))
        }
        120 => {
            let len = c.read_u32::<BigEndian>()? as usize;
            let mut vec = Vec::new();
            for _ in 0..len {
                vec.push(c.read_u8()?);
            }
            Ok(ProtocolValue::ByteArray(vec))
        }
        121 => Ok(ProtocolValue::Array(read_value_array_of_same_type(c)?)),
        122 => Ok(ProtocolValue::ObjectArray(read_value_array(c)?)),
        _ => Err(PhotonReadError::UnknownProtocolValueType(protocol_type)),
    }
}

pub fn read_value_array_of_same_type<'a>(c: &mut Cursor<&'a [u8]>) -> PhotonReadResult<Vec<ProtocolValue<'a>>> {
    let len = c.read_u16::<BigEndian>()?;
    let protocol_type = c.read_u8()?;
    let mut ret = Vec::new();
    for _i in 0..len {
        ret.push(read_value_of_type(c, protocol_type)?);
    }
    Ok(ret)
}

pub fn read_value_array<'a>(c: &mut Cursor<&'a [u8]>) -> PhotonReadResult<Vec<ProtocolValue<'a>>> {
    let len = c.read_u16::<BigEndian>()?;
    let mut ret = Vec::new();
    for _i in 0..len {
        ret.push(read_value(c)?);
    }
    Ok(ret)
}

pub fn read_hash_table<'a>(c: &mut Cursor<&'a [u8]>) -> PhotonReadResult<HashMap<ProtocolValue<'a>, ProtocolValue<'a>>> {
    let mut ret = HashMap::new();
    let len = c.read_u16::<BigEndian>()?;
    for _i in 0..len {
        ret.insert(read_value(c)?, read_value(c)?);
    }
    Ok(ret)
}

pub fn read_parameter_table<'a>(c: &mut Cursor<&'a [u8]>) -> PhotonReadResult<HashMap<u8, ProtocolValue<'a>>> {
    let mut ret = HashMap::new();
    let len = c.read_u16::<BigEndian>()?;
    for _i in 0..len {
        ret.insert(c.read_u8()?, read_value(c)?);
    }
    Ok(ret)
}

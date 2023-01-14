//
//  PythonDecoder.swift
//  touchBay editor
//
//  Created by MusicMaker on 04/09/2022.
//

import Foundation
import PythonLib
import PythonSwiftCore


private var PyStrDict: [String:PythonPointer] = [:]
private var PyIntDict: [Int:PythonPointer] = [:]

//func key2pyObject(key: String) -> PythonPointer {
//    if let obj = PyStrDict[key] {
//        return obj
//    }
//    let obj = key.python_str
//    PyStrDict[key] = obj
//    return obj
//}
//func int2pyObject(key: Int) -> PythonPointer {
//    if let obj = PyIntDict[key] {
//        return obj
//    }
//    let obj = key.object
//    PyIntDict[key] = obj
//    return obj
//}

//extension CodingKey {
//    
//    var pyStringValue: PythonPointer {
//        stringValue.withCString { PyUnicode_FromString }
//    }
//    var pyIntValue: PythonPointer {
//        PyLong_FromLong(intValue)
//    }
//    
//}

//protocol PyCodingKey: CodingKey {
//
//
//    typealias RawValue = PythonPointer
//    //var rawValue: PythonPointer {get set}
//    init?(rawValue: PythonPointer)
//}




//class _PyCodingKey: CodingKey, Equatable, RawRepresentable {
//    required init?(rawValue: PythonPointer) {
//        self.rawValue = rawValue
//        self.stringValue = ""
//        self.py_stringValue = rawValue
//    }
//
//    init?(rawValue: String) {
//        let _rawValue = key2pyObject(key: rawValue)
//        self.rawValue = _rawValue
//        stringValue = rawValue
//        py_stringValue = _rawValue
//    }
//
//    var rawValue: PythonPointer
//
//    typealias RawValue = PythonPointer
//
//    var stringValue: String
//    var py_stringValue: PythonPointer
//
//    required init?(stringValue: String) {
//        self.stringValue = stringValue
//
//        let _stringValue = key2pyObject(key: stringValue)
//        self.py_stringValue = _stringValue
//        rawValue = _stringValue
//
//    }
//
//    var intValue: Int?
//    var py_intValue: PythonPointer?
//
//    required init?(intValue: Int) {
//        self.intValue = intValue
//        self.py_intValue = int2pyObject(key: intValue)
//        let _stringValue = String(intValue)
//        stringValue = _stringValue
//        let _py_stringValue = key2pyObject(key: _stringValue)
//        py_stringValue = _py_stringValue
//        rawValue = _py_stringValue
//
//    }
//
//
//}
//
//class TestPyCodingKeys: _PyCodingKey {
//
//    static let test = key2pyObject(key: "")
//
//}

extension CodingKey {
    
    var py_stringValue: PythonPointer {
        
        if let obj = PyStrDict[stringValue] {
            return obj
        }
        let obj = stringValue.python_str
        PyStrDict[stringValue] = obj
        return obj
    }
}


class PyDecoder: Decoder {
    var codingPath: [CodingKey] = []
    //var codingPath: [PyCodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    let element: PythonPointer
    
    init(_ element: PythonPointer) {
        self.element = element
        Py_IncRef(element)
    }
    
    //deinit { Py_DecRef(element) }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return .init(
            PyKeyedDecodingContainer.init(
                self.element
            )
        )
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return PyUnkeyedDecodingContainer(self.element)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return PySingleValueDecodingContainer(element)
        
    }
    
    
}

class PySingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    let element: PythonPointer
    
    init(_ element: PythonPointer) {
        self.element = element
        Py_IncRef(element)
    }
    
    
    func decodeNil() -> Bool {
        element == PythonNone
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        try .init(object: element)
    }
    
    func decode(_ type: String.Type) throws -> String {
        try .init(object: element)
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        try .init(object: element)
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        try .init(object: element)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        try .init(object: element)
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        try .init(object: element)
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        try .init(object: element)
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        try .init(object: element)
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        try .init(object: element)
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        try .init(object: element)
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try .init(object: element)
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try .init(object: element)
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try .init(object: element)
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try .init(object: element)
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let decoder = PyDecoder(element)
        return try T.init(from: decoder)
    }
    
    
}

class PyUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    

    
    var codingPath: [CodingKey] = []
    
    var count: Int?
    var size: Int
    
    var isAtEnd: Bool = false //{ currentIndex == count ?? 0 }
    
    var currentIndex: Int = 0
    
    var element: PythonPointer
    let buffer: UnsafeBufferPointer<PythonPointer>
    //let iter:
    private var iter: UnsafeBufferPointer<PythonPointer>.Iterator
    
    init(_ element: PythonPointer) {
        pyPrint(element.xINCREF)
        //currentIndex = 0
        buffer = element.getBuffer()
        count = buffer.count
        size = buffer.count
        //count = buffer.count
        iter = buffer.makeIterator()
        
        self.element = element
    }
    
    @inlinable
    func next() -> PythonPointer {
        if currentIndex >= size {
            isAtEnd = true
            return nil
        }
        if let obj = iter.next() {
            print("STUFF IN LIST,,!,!,!,")
            pyPrint(obj.xINCREF)
            return obj
            //isAtEnd = false
        }
        print("NO MORE SHIT IN LIST OK!!!!")
            //self.element = nil
        isAtEnd = true
        return nil
        
    }
    
    func decodeNil() throws -> Bool {
        element == PythonNone
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError()
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        fatalError()
    }
    
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let obj = iter.next()! // else { throw PythonError.index }
        print("unkey decode T:",obj)
        let decoder = PyDecoder(obj)
        return try T(from: decoder)
    }
//    func decode(_ type: String.Type) throws -> String {
//        element.string ?? ""
//    }
//
//    func decode(_ type: Double.Type) throws -> Double {
//        element.double
//    }
//
//    func decode(_ type: Float.Type) throws -> Float {
//        element.float
//    }
//
//    func decode(_ type: Int.Type) throws -> Int {
//        element.int
//    }
//
//    func decode(_ type: Int8.Type) throws -> Int8 {
//        element.int8
//    }
//
//    func decode(_ type: Int16.Type) throws -> Int16 {
//        element.int16
//    }
    
//    func decode(_ type: Int32.Type) throws -> Int32 {
//        element.int32
//    }
//    
//    func decode(_ type: Int64.Type) throws -> Int64 {
//        PyLong_AsLongLong(element)
//    }
//    
//    func decode(_ type: UInt.Type) throws -> UInt {
//        element.uint
//    }
//    
//    func decode(_ type: UInt8.Type) throws -> UInt8 {
//        element.uint8
//    }
//    
//    func decode(_ type: UInt16.Type) throws -> UInt16 {
//        element.uint16
//    }
//    
//    func decode(_ type: UInt32.Type) throws -> UInt32 {
//        element.uint32
//    }
//    
//    func decode(_ type: UInt64.Type) throws -> UInt64 {
//        PyLong_AsUnsignedLongLong(element)
//    }
//    
//    
//    
//    func decode(_ type: Bool.Type) throws -> Bool {
//        element != PythonFalse
//    }
}

class PyKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    var codingPath: [CodingKey] = []
    
    var allKeys: [Key] = []
    
    let element: PythonPointer
    
    //private let decoder: PyDecoder
    
    init(_ element: PythonPointer) {
        self.element = element
    }
    
    deinit { Py_DecRef(element) }
    
    func contains(_ key: Key) -> Bool {
        PyObject_HasAttr(element, key.stringValue)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        if obj == PythonNone {
            Py_DecRef(obj)
            return false
        }

        return true
        
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }

        let bool = obj == PythonTrue
        Py_DecRef(obj)
        return bool
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        pyPrint(element)
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        
//        guard let out = obj.string else {
//            throw DecodingError.typeMismatch(String.self, DecodingError.Context.init(codingPath: codingPath, debugDescription: "\(key.stringValue) is not a <String>"))
//        }
        Py_DecRef(obj)
        return "out"
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        let out = PyFloat_AsDouble(obj)
        Py_DecRef(obj)
        return out
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        let out = PyFloat_AsDouble(obj)
        Py_DecRef(obj)
        return Float(out)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        let out = PyLong_AsLong(obj)
        Py_DecRef(obj)
        return out
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        let out = PyLong_AsLong(obj)
        Py_DecRef(obj)
        return .init(clamping: out)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        let obj = key.stringValue.withCString { PyDict_GetItemString(element, $0) }
        let out = PyLong_AsLong(obj)
        Py_DecRef(obj)
        return .init(clamping: out)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsLong(obj)
        Py_DecRef(obj)
        return .init(clamping: out)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsLongLong(obj)
        Py_DecRef(obj)
        return out
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsUnsignedLong(obj)
        Py_DecRef(obj)
        return out
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsUnsignedLong(obj)
        Py_DecRef(obj)
        return .init(clamping: out)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsUnsignedLong(obj)
        Py_DecRef(obj)
        return .init(clamping: out)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsUnsignedLong(obj)
        Py_DecRef(obj)
        return .init(clamping: out)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        let obj = PyObject_GetAttr(element, key.stringValue)
        let out = PyLong_AsUnsignedLongLong(obj)
        Py_DecRef(obj)
        return out
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        //let decoder = PyDecoder(element)
        print("keyed decoder",type, key, element)
        var obj: PyPointer
        //if PythonDict_Check(element) {
            obj = key.stringValue.withCString { PyDict_GetItemString(element, $0)}
            
            
//        } else if PythonList_Check(element) {
//            obj = pyli
//        }
//        else {
//            obj = PyObject_GetAttr(element, key.stringValue)
//        }
        
        let decoder = PyDecoder(obj)
        //pyPrint(obj.xINCREF)
        
        
        return try T(from: decoder)
        
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        .init(PyKeyedDecodingContainer<NestedKey>(element))
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        fatalError()
    }
    
    func superDecoder() throws -> Decoder {
        PyDecoder(element)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        let obj = PyObject_GetAttr(element, key.stringValue)
        return PyDecoder(obj)
    }
    
    
}











//
//  main.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 08/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation
import PythonLib
import PythonSwiftCore


fileprivate func pyCheckStatus(status: inout PyStatus, config: inout PyConfig, msg: String) {
    if PyStatus_Exception(status) != 0 {
        DEBUG_PRINT("\(msg)}: \(String(describing: status.err_msg))")
        PyConfig_Clear(&config)
        Py_ExitStatusException(status)
    }
}


class PythonHandler {
    
    static let shared = PythonHandler()
    
    var threadState: UnsafeMutablePointer<PyThreadState>?
    var status: PyStatus
    var preconfig: PyPreConfig
    var config: PyConfig
    
    private var _isRunning: Bool = false
    var defaultRunning: Bool {
        get {
            _isRunning
        }
        set {
            if !_isRunning {
                _isRunning = newValue
                start(
                    stdlib: APP_FOLDER.appendingPathComponent("python-stdlib").path,
                    app_packages: PYTHON_EXTRA_MODULES,
                    debug: false
                )
            }
            
            
        }
    }
    
    init() {
        
        status = .init()
        preconfig = .init()
        config = .init()

    }
    
    
    
    func start(stdlib: String, app_packages: [String], debug: Bool) {
        var ret = 0
        
        //    let python_home: String? = nil
        //    let app_module_name: String? = nil
        //var path: String = ""
        //    let traceback_str: String? = nil
        //var wtmp_str: UnsafePointer<Int32>? = nil
        //    let app_module_str: UnsafePointer<Int8>? = nil
        //    let nslog_script: UnsafePointer<Int8>? = nil
        //    let app_module: PyObject? = nil
        //    let module: PyObject? = nil
        //    let module_attr: PyObject? = nil
        //    let method_args: PyObject? = nil
        //    let result: PyObject? = nil
        //    let exc_type: PyObject? = nil
        //    let exc_value: PyObject? = nil
        //    let exc_traceback: PyObject? = nil
        //    let systemExit_code: PyObject? = nil
        
//        let resourcePath = Bundle.main.resourcePath!
        
        // Generate an isolated Python configuration.
        if debug { DEBUG_PRINT("Configuring isolated Python...") }
        PyPreConfig_InitIsolatedConfig(&preconfig)
        PyConfig_InitIsolatedConfig(&config)
        
        // Configure the Python interpreter:
        // Enforce UTF-8 encoding for stderr, stdout, file-system encoding and locale.
        // See https://docs.python.org/3/library/os.html#python-utf-8-mode.
        
        //  Converted to Swift 5.7.1 by Swiftify v5.7.32383 - https://swiftify.com/
        preconfig.utf8_mode = 1
        // Don't buffer stdio. We want output to appears in the log immediately
        config.buffered_stdio = 0
        // Don't write bytecode; we can't modify the app bundle
        // after it has been signed.
        config.write_bytecode = 0
        // Isolated apps need to set the full PYTHONPATH manually.
        config.module_search_paths_set = 1
        
        if debug { DEBUG_PRINT("Pre-initializing Python runtime...") }
        status = Py_PreInitialize(&preconfig)
        if PyStatus_Exception(status) != 0 {
            DEBUG_PRINT("Unable to pre-initialize Python interpreter: \(String(describing: status.err_msg))")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        
        // Read the site config
        status = PyConfig_Read(&config)
        pyCheckStatus(status: &status, config: &config, msg: "Unable to read site config")
        
        // The unpacked form of the stdlib
        //path = stdlib_path
        if debug { DEBUG_PRINT("- \(stdlib)") }
        var wtmp_str = stdlib.withCString { Py_DecodeLocale($0, nil) }
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        
        pyCheckStatus(status: &status, config: &config, msg: "Unable to set unpacked form of stdlib path")
        PyMem_RawFree(wtmp_str)
        
        // Add the stdlib binary modules path
        let dynload_path = "\(stdlib)/lib-dynload"
        if debug { DEBUG_PRINT("- \(dynload_path)") }
        wtmp_str = dynload_path.withCString { Py_DecodeLocale($0, nil) }
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        pyCheckStatus(status: &status, config: &config, msg: "Unable to set stdlib binary module path")
        PyMem_RawFree(wtmp_str)
        
        
        // Add the app_packages path
        //path = "\(resourcePath)/app_packages"
        for package in app_packages {
            if debug { DEBUG_PRINT("- \(package)") }
            wtmp_str = package.withCString { Py_DecodeLocale($0, nil) }
            status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
            pyCheckStatus(status: &status, config: &config, msg: "Unable to set app packages path")
            PyMem_RawFree(wtmp_str)
        }
        
        //    DEBUG_PRINT("Configure argc/argv...")
        //    status = PyConfig_SetBytesArgv(&config, argc, argv)
        //    pyCheckStatus(status: &status, config: &config, msg: "Unable to configured argc/argv")
        
        
        if debug { DEBUG_PRINT("Initializing Python runtime...") }
        status = Py_InitializeFromConfig(&config)
        pyCheckStatus(status: &status, config: &config, msg: "Unable to initialize Python interpreter")
        
        
        
        //exit(Int32(ret))
        //return ret
    }
    
    
    deinit {
        Py_Finalize();
    }
}

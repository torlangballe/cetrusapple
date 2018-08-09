//
//  ZGLShaderProgram.swift
//  capsulefm
//
//  Created by Tor Langballe on /4/5/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//
//  https://developer.apple.com/library/ios/documentation/3ddrawing/conceptual/opengles_programmingguide/introduction/introduction.html
//  http://www.opengl.org/wiki/GLSL_Predefined_Variables#Fragment_shader_inputs
//  http://stackoverflow.com/questions/17602130/cant-draw-triangle-using-opengl - very good
//  https://developer.apple.com/library/prerelease/ios/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/BestPracticesforShaders/BestPracticesforShaders.html#//apple_ref/doc/uid/TP40008793-CH7-SW3

import Foundation
import OpenGLES

typealias GLhandleARB=GLuint

class ZGLShaderProgram {
    //    let _uniformNormalMatrix,
    //    let _uniformModelViewProjectionMatrix;
        
    var hvertex = false
    var hfragment = false
    var names = [String:GLuint]()
    var program: GLuint? = nil
    
    // ZGLShaderProgram *************************************************************************
    
    init?(vertsource:String, fragsource:String) {
        program = glCreateProgram();
        if !Add(vertsource, vertex:true) {
            return nil
        }
        if !Add(fragsource, vertex:false) {
            return nil
        }
        if !Link() {
            return nil
        }
    }

    convenience init?(fvert:ZFileUrl, ffrag:ZFileUrl) {
        let (sv, _) = ZStr.LoadFromFile(fvert)
        let (sf, _) = ZStr.LoadFromFile(ffrag)
        if !sv.isEmpty && !sf.isEmpty {
            self.init(vertsource:sv, fragsource:sf)
        }
        return nil
    }
    
    func Use(_ use:Bool = true) {
        glUseProgram((use ? program : nil)!)
    }
    
    @discardableResult func dumpLog(_ shader:GLuint, logLength:GLsizei, vertex:Bool?) -> String {

        let BSIZE:GLsizei = 1024 * 20

        //        var buffer = [CChar](count: 256, repeatedValue: CChar(0))
        var len:GLsizei = 0
        
        let log = Array<GLchar>(repeating: 0, count: Int(BSIZE))
        log.withUnsafeBufferPointer { logPointer -> Void in
            if vertex == nil {
                glGetProgramInfoLog(shader, logLength, &len, UnsafeMutablePointer(mutating: logPointer.baseAddress))
            } else {
                glGetShaderInfoLog(shader, logLength, &len, UnsafeMutablePointer(mutating: logPointer.baseAddress))
            }
        }
        let slog = String(validatingUTF8: log)!
        var str = ""
        if vertex == nil {
            str = "linking"
        } else if vertex! == true {
            str = "vertex"
        } else if vertex! == false {
            str = "fragment"
        }
        ZDebug.Print(str + ":\n" + slog)
        return slog;
    }

    
    func Add(_ source:String, vertex:Bool) -> Bool {
        var logLength:GLint = 0
        var compiled:GLint = 0
    
        var c = 0
        var nsource = ""
        var name = ""
        source.enumerateLines { (part, quit) in
            nsource += "\n"
            if ZStr.HasPrefix(part, prefix:"#include ", rest:&name) {
                let sinc = self.getIncludedText(ZStr.Trim(name, chars:"\""))
                nsource += sinc
                let t = c + ZStr.CountLines(sinc)
                ZDebug.Print("Included %@ from line %d to %d", name, c, t)
                c = t
            } else {
                nsource += part
                c += 1
            }
        }
        let source = nsource
            let target = GLuint(vertex ? GL_VERTEX_SHADER : GL_FRAGMENT_SHADER)
        let _ = source.cString(using: String.Encoding.utf8)! // s
        //!!!        glShaderSource(target, GLsizei(1), UnsafePointer(s), nil)

        let handle = glCreateShader(target)
        ///!!!        glShaderSource(handle, GLsizei(1), UnsafePointer(s), nil)
        if ZGLCheckError() {
            return false
        }
        
        glCompileShader(handle);
        if ZGLCheckError() {
            return false
        }
        
        glGetShaderiv(handle, GLenum(GL_COMPILE_STATUS), &compiled);
        glGetShaderiv(handle, GLenum(GL_INFO_LOG_LENGTH), &logLength);
        if logLength > 0 {
            dumpLog(handle, logLength:logLength, vertex:vertex)
        }
        if compiled == 0 {
            return false
        }
        
        glAttachShader(program!, handle);
        if vertex {
            hvertex = true
        } else {
            hfragment = true
        }
        return true;
    }
    
    func Link() -> Bool {
        var logLength:GLint = 0
        var linked:GLint = 0
    
        glLinkProgram(program!)
        if ZGLCheckError() {
            return false
        }

        glGetProgramiv(program!, GLenum(GL_LINK_STATUS), &linked)
        glGetProgramiv(program!, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            dumpLog(program!, logLength:logLength, vertex:nil)
            if linked == 0 {
                return false
            }
        }
        return true;
    }

    func getIncludedText(_ name:String) -> String {
        let file = ZFolders.GetFileInFolderType(.resources, addPath:"zglshadersinludes/" + name + ".glsl");
        let (str ,_) = ZStr.LoadFromFile(file)
        return str
    }
    
    func SetUniformArgI(_ c:Int, name:String, a1:Int, a2:Int = 0, a3:Int = 0, a4:Int = 0) {
        let sname = name.cString(using: String.Encoding.utf8)
        //        glShaderSource(target, GLsizei(1), UnsafePointer(s!), nil)

        let gllocation = glGetUniformLocation(program!, sname!)
        switch c {
            case 1:
                glUniform1i(gllocation, GLint(a1))
            case 2:
                glUniform2i(gllocation, GLint(a1), GLint(a2))
            case 3:
                glUniform3i(gllocation, GLint(a1), GLint(a2), GLint(a3))
            case 4:
                glUniform4i(gllocation, GLint(a1), GLint(a2), GLint(a3), GLint(a4))
            default:
                break
        }
    }
    func SetUniformArgF(_ c:Int, name:String, a1:Float, a2:Float = 0, a3:Float = 0, a4:Float = 0) {
        let sname = name.cString(using: String.Encoding.utf8)
        //        glShaderSource(target, GLsizei(1), UnsafePointer(s!), nil)
        
        let gllocation = glGetUniformLocation(program!, sname!)
        switch c {
        case 1:
            glUniform1f(gllocation, GLfloat(a1))
        case 2:
            glUniform2f(gllocation, GLfloat(a1), GLfloat(a2))
        case 3:
            glUniform3f(gllocation, GLfloat(a1), GLfloat(a2), GLfloat(a3))
        case 4:
            glUniform4f(gllocation, GLfloat(a1), GLfloat(a2), GLfloat(a3), GLfloat(a4))
        default:
            break
        }
    }

    func SetVertexAttributeF(_ c:Int, name:String, a1:Float, a2:Float = 0, a3:Float = 0, a4:Float = 0) {
    
        if let loc = names[name] {
            switch c {
                case 1: glVertexAttrib1f(loc, a1)
                case 2: glVertexAttrib2f(loc, a1, a2)
                case 3: glVertexAttrib3f(loc, a1, a2, a3)
                default: glVertexAttrib4f(loc, a1, a2, a3, a4)
            }
        }
    }
    
    func SetColorUniformValue(_ name:String, col:ZColor) {
        let c = col.RGBA
        SetUniformArgF(4, name:name, a1:c.r, a2:c.g, a3:c.b, a4:c.a)
    }

    func UseNamedValues(_ useNames:String...) {
        for n in useNames {
            let loc = glGetAttribLocation(program!, n)
            names[n] = GLuint(loc)
        }
    }
}


//
//  ZGLUtil.swift
//  capsulefm
//
//  Created by Tor Langballe on /4/5/16.
//  Copyright © 2016 Capsule.fm. All rights reserved.
//

import Foundation
import OpenGLES

func ZGLDrawQuad(_ shader:ZGLShaderProgram, rect:ZRect, time:Double, gradient:[[ZColor]]) {
    shader.SetUniformArgF(1, name:"time", a1:Float(time))
    shader.SetColorUniformValue("colorTL", col:gradient[0][0])
    shader.SetColorUniformValue("colorTR", col:gradient[1][0])
    shader.SetColorUniformValue("colorBR", col:gradient[1][1])
    shader.SetColorUniformValue("colorBL", col:gradient[0][1])

    let fan : [GLfloat] = [
        GLfloat(rect.Min.x), GLfloat(rect.Min.y),
        GLfloat(rect.Max.x), GLfloat(rect.Min.y),
        GLfloat(rect.Max.x), GLfloat(rect.Max.y),
        GLfloat(rect.Min.x), GLfloat(rect.Max.y),
    ]
    let posIn : [GLfloat] = [
        0, 0,
        1, 0,
        1, 1,
        0, 1,
    ]
    
    if let posAIndex = shader.names["colorPosIn"] {
        glEnableVertexAttribArray(posAIndex)
        glVertexAttribPointer(posAIndex, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, posIn)
    }
    
    if let vertexAIndex = shader.names["vertexIn"] {
        glEnableVertexAttribArray(vertexAIndex)
        glVertexAttribPointer(vertexAIndex, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, fan)
    }
    
    glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, 4)
}
    /*
func ZGLDrawQuadWithGradients(shader:ZGLShaderProgram, rect:ZRect, time:Double , info:ZGLQuadGradientInfo) {
    double      t;
    ZFRGBAColor c[2][2];
    int         i, j;
    
    let t = time - info.start
    if info.reverse {
        t = abs(info.period - mod(t, info.period * 2)) / info.period
    } else {
        t = mod(t, info.period) / info.period
        for i in 0..< 2 {
            for j in 0..< 2 {
                c[i][j] = ZMath.MixedArrayValueAtT(info.cols[i][j], t:t)
            }
        }
    }
    ZGLDrawQuad(shader, rect, t, c);
}
    */

func ZGLCheckError() -> Bool {
    let err = glGetError()
    if err != GLenum(GL_NO_ERROR) {
    }
    return err != GLenum(GL_NO_ERROR)
}


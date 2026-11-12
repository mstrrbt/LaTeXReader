//
//  ContentView.swift
//  LaTeXReader Watch App
//
//  Created by Alexander on 11/10/26.
//

import SwiftUI
import CoreGraphics

func renderPage(_ page: CGPDFPage, width: CGFloat, scale: CGFloat = 2) -> CGImage? {
    let box = page.getBoxRect(.mediaBox)
    guard box.width > 0 else { return nil }

    let pxW = Int(width * scale)
    let pxH = Int(CGFloat(pxW) * box.height / box.width)

    guard let ctx = CGContext(
        data: nil,
        width: pxW,
        height: pxH,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    ) else { return nil }

    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: pxW, height: pxH))

    // явный масштаб: ширина страницы PDF -> ширина изображения
    let s = CGFloat(pxW) / box.width
    ctx.scaleBy(x: s, y: s)
    ctx.translateBy(x: -box.minX, y: -box.minY)
    ctx.drawPDFPage(page)

    return ctx.makeImage()
}

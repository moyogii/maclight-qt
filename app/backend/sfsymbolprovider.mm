#include "sfsymbolprovider.h"

#include <QGuiApplication>
#include <QPainter>

#ifdef Q_OS_DARWIN
#include <AppKit/AppKit.h>
#endif

SfSymbolProvider::SfSymbolProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

SfSymbolProvider::~SfSymbolProvider()
{
}

QImage SfSymbolProvider::requestImage(const QString& id, QSize* size, const QSize& requestedSize)
{
#ifdef Q_OS_DARWIN
    @autoreleasepool {
        QString symbolName = id;
        qreal dpr = qApp ? qApp->devicePixelRatio() : 1.0;
        int targetWidth = requestedSize.isEmpty() ? 24 : requestedSize.width();
        int targetHeight = requestedSize.isEmpty() ? 24 : requestedSize.height();
        int renderWidth = static_cast<int>(targetWidth * dpr);
        int renderHeight = static_cast<int>(targetHeight * dpr);

        NSString* nsSymbolName = symbolName.toNSString();

        if (@available(macOS 11.0, *)) {
            NSImage* nsImage = [NSImage imageWithSystemSymbolName:nsSymbolName accessibilityDescription:nil];

            if (nsImage) {
                NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
                    initWithBitmapDataPlanes:nullptr
                                  pixelsWide:renderWidth
                                  pixelsHigh:renderHeight
                               bitsPerSample:8
                             samplesPerPixel:4
                                    hasAlpha:YES
                                    isPlanar:NO
                              colorSpaceName:NSCalibratedRGBColorSpace
                                 bytesPerRow:0
                                bitsPerPixel:32];

                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];

                [[NSColor clearColor] setFill];
                NSRectFill(NSMakeRect(0, 0, renderWidth, renderHeight));

                [nsImage drawInRect:NSMakeRect(0, 0, renderWidth, renderHeight)
                           fromRect:NSZeroRect
                          operation:NSCompositingOperationSourceOver
                           fraction:1.0];

                [NSGraphicsContext restoreGraphicsState];

                CGImageRef cgImage = [rep CGImage];

#if !__has_feature(objc_arc)
                [rep release];
#endif

                if (cgImage) {
                    QImage result(renderWidth, renderHeight, QImage::Format_ARGB32_Premultiplied);
                    result.fill(Qt::transparent);

                    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
                    CGContextRef context = CGBitmapContextCreate(
                        result.bits(),
                        renderWidth,
                        renderHeight,
                        8,
                        result.bytesPerLine(),
                        colorSpace,
                        kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host
                    );
                    CGColorSpaceRelease(colorSpace);

                    CGContextDrawImage(context, CGRectMake(0, 0, renderWidth, renderHeight), cgImage);
                    CGContextRelease(context);

                    if (dpr > 1.0) {
                        result.setDevicePixelRatio(dpr);
                    }

                    QPainter painter(&result);
                    painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
                    painter.fillRect(result.rect(), Qt::white);
                    painter.end();

                    if (size) {
                        *size = QSize(targetWidth, targetHeight);
                    }
                    return result;
                }
            }
        }
    }
#else
    Q_UNUSED(id)
    Q_UNUSED(size)
    Q_UNUSED(requestedSize)
#endif

    return QImage();
}

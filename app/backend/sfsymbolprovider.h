#pragma once

#include <QObject>
#include <QQuickImageProvider>
#include <QImage>

class SfSymbolProvider : public QQuickImageProvider
{
public:
    SfSymbolProvider();
    ~SfSymbolProvider();

    QImage requestImage(const QString& id, QSize* size, const QSize& requestedSize) override;
};

#include "metalhudutils.h"
#include "SDL_compat.h"

#include <QByteArray>
#include <QQuickWindow>

#include <SDL_render.h>

#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>

namespace {

static bool shouldAdjustHudMode()
{
    QByteArray enabled = qgetenv("MTL_HUD_ENABLED");
    return enabled == "1";
}

static NSString* modeToNSString(MetalHudUtils::LayerMode mode)
{
    switch (mode) {
    case MetalHudUtils::LayerMode::Main:
        return @"main";
    case MetalHudUtils::LayerMode::Disabled:
        return @"disabled";
    case MetalHudUtils::LayerMode::Default:
    default:
        return @"default";
    }
}

static void setHudModeOnMetalLayer(CAMetalLayer* metalLayer, MetalHudUtils::LayerMode mode)
{
    if (metalLayer == nil) {
        return;
    }

    if (!shouldAdjustHudMode()) {
        return;
    }

    if (@available(macOS 13.0, *)) {
        NSMutableDictionary* hudProperties = [NSMutableDictionary dictionary];
        if (metalLayer.developerHUDProperties != nil) {
            [hudProperties addEntriesFromDictionary:metalLayer.developerHUDProperties];
        }

        hudProperties[@"mode"] = modeToNSString(mode);
        metalLayer.developerHUDProperties = hudProperties;
    }
}

static void setHudModeOnLayerTree(CALayer* layer, MetalHudUtils::LayerMode mode)
{
    if (layer == nil) {
        return;
    }

    if ([layer isKindOfClass:[CAMetalLayer class]]) {
        setHudModeOnMetalLayer((CAMetalLayer*)layer, mode);
    }

    for (CALayer* sublayer in layer.sublayers) {
        setHudModeOnLayerTree(sublayer, mode);
    }
}

static void setHudModeOnViewTree(NSView* view, MetalHudUtils::LayerMode mode)
{
    if (view == nil) {
        return;
    }

    setHudModeOnLayerTree(view.layer, mode);

    for (NSView* subview in view.subviews) {
        setHudModeOnViewTree(subview, mode);
    }
}

static NSApplicationPresentationOptions s_OriginalPresentationOptions = 0;
static bool s_PresentationOptionsSaved = false;

}

namespace MetalHudUtils {

void setMetalLayerHudMode(void* layer, LayerMode mode)
{
    setHudModeOnMetalLayer((CAMetalLayer*)layer, mode);
}

void setSdlRendererHudMode(SDL_Renderer* renderer, LayerMode mode)
{
    if (renderer == nullptr) {
        return;
    }

#if SDL_VERSION_ATLEAST(3, 0, 0)
    void* layer = SDL_GetRenderMetalLayer(renderer);
#else
    void* layer = SDL_RenderGetMetalLayer(renderer);
#endif

    setMetalLayerHudMode(layer, mode);
}

void setQtWindowHudMode(QQuickWindow* window, LayerMode mode)
{
    if (window == nullptr) {
        return;
    }

    WId windowId = window->winId();
    if (windowId == 0) {
        return;
    }

    NSView* view = (NSView*)(windowId);
    setHudModeOnViewTree(view, mode);
}

void setDockHiddenForStreaming(bool enabled)
{
    @autoreleasepool {
        NSApplication* app = [NSApplication sharedApplication];
        if (app == nil) {
            return;
        }

        if (enabled) {
            if (!s_PresentationOptionsSaved) {
                s_OriginalPresentationOptions = [app currentSystemPresentationOptions];
                s_PresentationOptionsSaved = true;
            }

            NSApplicationPresentationOptions newOptions = s_OriginalPresentationOptions;
            newOptions |= NSApplicationPresentationHideDock;
            newOptions &= ~NSApplicationPresentationAutoHideDock;

            [app setPresentationOptions:newOptions];
        } else {
            if (s_PresentationOptionsSaved) {
                [app setPresentationOptions:s_OriginalPresentationOptions];
                s_PresentationOptionsSaved = false;
            }
        }
    }
}

}

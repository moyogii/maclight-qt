#pragma once

class QQuickWindow;
struct SDL_Renderer;

namespace MetalHudUtils {

enum class LayerMode {
    Default,
    Main,
    Disabled,
};

void setQtWindowHudMode(QQuickWindow* window, LayerMode mode);
void setSdlRendererHudMode(SDL_Renderer* renderer, LayerMode mode);
void setMetalLayerHudMode(void* layer, LayerMode mode);

}

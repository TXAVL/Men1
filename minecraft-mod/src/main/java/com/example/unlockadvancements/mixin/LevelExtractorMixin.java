package com.example.unlockadvancements.mixin;

import com.example.unlockadvancements.MorphManager;
import net.minecraft.client.Camera;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.renderer.culling.Frustum;
import net.minecraft.client.renderer.extract.LevelExtractor;
import net.minecraft.client.renderer.state.level.LevelRenderState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(LevelExtractor.class)
public class LevelExtractorMixin {
    // Only swap the player's render state while the world's entity list is being extracted.
    // Every other caller (local player state, inventory preview, hand rendering...) requires an AvatarRenderState.
    @Inject(method = "extractVisibleEntities", at = @At("HEAD"))
    private void onStartExtractVisibleEntities(Camera camera, Frustum frustum, DeltaTracker deltaTracker, LevelRenderState levelRenderState, CallbackInfo ci) {
        MorphManager.isExtractingWorldEntities = true;
    }

    @Inject(method = "extractVisibleEntities", at = @At("RETURN"))
    private void onEndExtractVisibleEntities(Camera camera, Frustum frustum, DeltaTracker deltaTracker, LevelRenderState levelRenderState, CallbackInfo ci) {
        MorphManager.isExtractingWorldEntities = false;
    }

    @Inject(method = "extract", at = @At("RETURN"))
    private void onExtractEnd(DeltaTracker deltaTracker, Camera camera, float tickDelta, CallbackInfo ci) {
        MorphManager.isExtractingWorldEntities = false;
    }
}

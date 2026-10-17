package com.example.unlockadvancements.mixin;

import com.example.unlockadvancements.MorphManager;
import net.minecraft.client.Minecraft;
import net.minecraft.client.player.LocalPlayer;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(Minecraft.class)
public abstract class MinecraftMixin {
    @Shadow public Entity crosshairPickEntity;
    @Shadow public LocalPlayer player;

    // Morph state lives in static maps shared by the client and the integrated server (same JVM),
    // so it is only ever changed here on the render thread. Never touch the client player from the server thread.
    @Inject(method = "startAttack", at = @At("HEAD"), cancellable = true)
    private void onStartAttack(CallbackInfoReturnable<Boolean> cir) {
        if (player == null) return;

        // If wearing mask
        if (MorphManager.isWearingMask(player)) {
            // Shift + Click: Unmorph
            if (player.isShiftKeyDown()) {
                if (MorphManager.isMorphed(player)) {
                    MorphManager.unmorph(player);
                    cir.setReturnValue(true);
                    return;
                }
            }

            // Click on living entity: Morph into it!
            if (crosshairPickEntity instanceof LivingEntity target && !(target instanceof Player)) {
                MorphManager.morph(player, target);
                cir.setReturnValue(true);
            }
        }
    }

    @Inject(method = "startUseItem", at = @At("HEAD"), cancellable = true)
    private void onStartUseItem(CallbackInfo ci) {
        if (player == null) return;

        // On mobile / touchscreen (PojavLauncher), tapping an entity may trigger startUseItem
        if (MorphManager.isWearingMask(player)) {
            if (crosshairPickEntity instanceof LivingEntity target && !(target instanceof Player)) {
                MorphManager.morph(player, target);
                ci.cancel();
            }
        }
    }
}

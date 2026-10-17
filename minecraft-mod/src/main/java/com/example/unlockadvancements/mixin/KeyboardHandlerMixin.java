package com.example.unlockadvancements.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import com.mojang.blaze3d.platform.InputConstants;
import net.minecraft.client.KeyboardHandler;
import net.minecraft.client.Minecraft;
import net.minecraft.client.input.KeyEvent;
import com.example.unlockadvancements.UnlockAdvancementsMod;

@Mixin(KeyboardHandler.class)
public class KeyboardHandlerMixin {
    @Shadow
    private Minecraft minecraft;

    @Inject(method = "keyPress(JILnet/minecraft/client/input/KeyEvent;)V", at = @At("HEAD"))
    private void onKeyPress(long window, int action, KeyEvent event, CallbackInfo ci) {
        // Chi xu ly luc nhan phim (PRESS = 1), bo qua REPEAT (-1) va RELEASE (0)
        if (action != InputConstants.PRESS) return;
        if (this.minecraft == null || this.minecraft.player == null || this.minecraft.gui == null) return;
        // Dang mo chat, menu tam dung, hom do... thi bo qua
        if (this.minecraft.gui.screen() != null) return;

        // Game 26.x dung SDL scancode (InputConstants.KEY_*)
        int k = event.key();
        boolean isShift = event.hasShiftDown()
            || InputConstants.isKeyDown(InputConstants.KEY_LSHIFT)
            || InputConstants.isKeyDown(InputConstants.KEY_RSHIFT);

        // Phim M / G / H: Mo Menu
        if (k == InputConstants.KEY_M || k == InputConstants.KEY_G || k == InputConstants.KEY_H) {
            this.minecraft.setScreenAndShow(new com.example.unlockadvancements.MorphMenuScreen());
            return;
        }

        // Shift + 7 (hang so hoac numpad) hoac F7: Mo khoa thanh tuu
        boolean isKey7 = k == InputConstants.KEY_7 || k == InputConstants.KEY_NUMPAD7;
        if ((isShift && isKey7) || k == InputConstants.KEY_F7) {
            UnlockAdvancementsMod.LOGGER.info("Kich hoat mo khoa thanh tuu boi phim! Key=" + k + ", Shift=" + isShift);
            UnlockAdvancementsMod.unlockAll(this.minecraft);
        }
    }
}

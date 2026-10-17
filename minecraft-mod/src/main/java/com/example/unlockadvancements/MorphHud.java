package com.example.unlockadvancements;

import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.Font;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.network.chat.Component;
import net.minecraft.world.entity.player.Player;

public class MorphHud {
    public static boolean enabled = true;

    public static void render(GuiGraphicsExtractor extractor, Font font) {
        if (!enabled) return;
        Minecraft mc = Minecraft.getInstance();
        Player player = mc.player;
        if (player == null) return;

        int x = 8;
        int y = 8;
        int width = 175;
        int height = 58;

        boolean morphed = MorphManager.isMorphed(player);
        boolean wearingMask = MorphManager.isWearingMask(player);
        int maxSuspicion = MorphManager.getMaxSuspicion(player);
        boolean alerted = MorphManager.isAlerted(player);
        String mobName = MorphManager.getMorphedName(player);

        // Adjust height if suspicion bar is active
        if (morphed && (maxSuspicion > 0 || alerted)) {
            height = 68;
        }

        // Outer glowing cyan/gold border
        extractor.fill(x - 1, y - 1, x + width + 1, y + height + 1, 0xFF00E5FF);
        // Inner translucent dark slate panel
        extractor.fill(x, y, x + width, y + height, 0xD010141E);

        // Header Title
        extractor.text(font, Component.literal("\u00a76\u00a7l\u2726 MORPH & DISGUISE HUD \u2726"), x + 6, y + 5, 0xFFFFFFFF);

        // Line 1: Morph form
        String formStr = morphed ? ("\u00a7a" + mobName) : "\u00a7bCon Ng\u01b0\u1eddi";
        extractor.text(font, Component.literal("\u00a77D\u1ea1ng: " + formStr), x + 6, y + 17, 0xFFE0E0E0);

        // Line 2: Mask status
        String maskStr = wearingMask ? "\u00a7a\u0110ang \u0110eo \u2714" : "\u00a7cCh\u01b0a \u0110eo \u2718";
        extractor.text(font, Component.literal("\u00a77M\u1eb7t N\u1ea1: " + maskStr), x + 6, y + 28, 0xFFE0E0E0);

        // Line 3: AI Detection State
        if (morphed) {
            if (alerted) {
                extractor.text(font, Component.literal("\u00a7c\u00a7l\ud83d\udea8 B\u1eca PH\u00c1T HI\u1ec6N! Qu\u00e1i t\u1ea5n c\u00f4ng!"), x + 6, y + 39, 0xFFFF3333);
            } else if (maxSuspicion > 0) {
                int sec = Math.max(1, (100 - maxSuspicion) / 20);
                int percent = maxSuspicion;
                extractor.text(font, Component.literal("\u00a7e\u26a0\ufe0f Nghi ng\u1edd: \u00a7c" + percent + "% (" + sec + "s)"), x + 6, y + 39, 0xFFFFAA00);

                // Suspicion progress bar
                int barX = x + 6;
                int barY = y + 50;
                int barWidth = width - 12;
                int progressWidth = Math.min(barWidth, (int) (barWidth * (maxSuspicion / 100.0f)));

                extractor.fill(barX, barY, barX + barWidth, barY + 4, 0xFF333333); // Background
                int barColor = maxSuspicion > 70 ? 0xFFFF2222 : (maxSuspicion > 40 ? 0xFFFFCC00 : 0xFF55FF55);
                extractor.fill(barX, barY, barX + progressWidth, barY + 4, barColor); // Progress
            } else {
                extractor.text(font, Component.literal("\u00a72\u2714 An to\u00e0n: Qu\u00e1i coi l\u00e0 b\u1ea1n"), x + 6, y + 39, 0xFF55FF55);
            }
        } else {
            extractor.text(font, Component.literal("\u00a78Nh\u1ea5p v\u00e0o Mob \u0111\u1ec3 h\u00f3a th\u00e2n"), x + 6, y + 39, 0xFFAAAAAA);
        }

        // Bottom shortcut tip
        extractor.text(font, Component.literal("\u00a78[M] M\u1edf Menu | [Shift+LClick] Tho\u00e1t"), x + 6, y + (height - 10), 0xFF888888);
    }
}

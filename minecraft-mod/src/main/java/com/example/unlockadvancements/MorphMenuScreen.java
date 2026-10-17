package com.example.unlockadvancements;

import net.minecraft.client.gui.Font;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.Component;
import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.EntityTypes;

public class MorphMenuScreen extends Screen {

    public MorphMenuScreen() {
        super(Component.literal("Menu H\u00f3a Th\u00e2n & VIP"));
    }

    @Override
    protected void init() {
        int centerX = this.width / 2;
        int startY = 42;
        int btnWidth = 100;
        int btnHeight = 20;
        int gap = 4;

        // Column 1 (Left): Monsters
        addRenderableWidget(Button.builder(Component.literal("\ud83e\udddf Zombie"), b -> morph(EntityTypes.ZOMBIE, "Zombie"))
            .bounds(centerX - 158, startY, btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udca5 Creeper"), b -> morph(EntityTypes.CREEPER, "Creeper"))
            .bounds(centerX - 158, startY + (btnHeight + gap), btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83c\udff9 Skeleton"), b -> morph(EntityTypes.SKELETON, "Skeleton"))
            .bounds(centerX - 158, startY + 2 * (btnHeight + gap), btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udd77\ufe0f Nh\u1ec7n"), b -> morph(EntityTypes.SPIDER, "Nh\u1ec7n"))
            .bounds(centerX - 158, startY + 3 * (btnHeight + gap), btnWidth, btnHeight).build());

        // Column 2 (Middle): Powerful & Special Mobs
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udd2e Enderman"), b -> morph(EntityTypes.ENDERMAN, "Enderman"))
            .bounds(centerX - 50, startY, btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83e\uddd9 Ph\u00f9 Th\u1ee7y"), b -> morph(EntityTypes.WITCH, "Ph\u00f9 Th\u1ee7y"))
            .bounds(centerX - 50, startY + (btnHeight + gap), btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udee1\ufe0f Iron Golem"), b -> morph(EntityTypes.IRON_GOLEM, "Iron Golem"))
            .bounds(centerX - 50, startY + 2 * (btnHeight + gap), btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udc79 Warden"), b -> morph(EntityTypes.WARDEN, "Warden"))
            .bounds(centerX - 50, startY + 3 * (btnHeight + gap), btnWidth, btnHeight).build());

        // Column 3 (Right): Animals & 1.21 Mobs
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udc2e Con B\u00f2"), b -> morph(EntityTypes.COW, "B\u00f2"))
            .bounds(centerX + 58, startY, btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udc37 Con Heo"), b -> morph(EntityTypes.PIG, "Heo"))
            .bounds(centerX + 58, startY + (btnHeight + gap), btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udc3a Con S\u00f3i"), b -> morph(EntityTypes.WOLF, "S\u00f3i"))
            .bounds(centerX + 58, startY + 2 * (btnHeight + gap), btnWidth, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udca8 Breeze 1.21"), b -> morph(EntityTypes.BREEZE, "Breeze"))
            .bounds(centerX + 58, startY + 3 * (btnHeight + gap), btnWidth, btnHeight).build());

        // Control Row 1 (Unmorph & Mask)
        int row2Y = startY + 4 * (btnHeight + gap) + 8;
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udc64 Tr\u1edf V\u1ec1 Con Ng\u01b0\u1eddi"), b -> unmorph())
            .bounds(centerX - 158, row2Y, 153, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83c\udfad L\u1ea5y M\u1eb7t N\u1ea1 H\u00f3a Th\u00e2n"), b -> giveMask())
            .bounds(centerX + 5, row2Y, 153, btnHeight).build());

        // Control Row 2 (VIP & Advancements & XP)
        int row3Y = row2Y + btnHeight + gap;
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udc51 \u0110\u1ed3 Th\u1ea7n VIP"), b -> giveVip())
            .bounds(centerX - 158, row3Y, 100, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\ud83c\udf1f M\u1edf Kh\u00f3a All"), b -> unlockAll())
            .bounds(centerX - 50, row3Y, 100, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\u26a1 +10 C\u1ea5p XP"), b -> addXp())
            .bounds(centerX + 58, row3Y, 100, btnHeight).build());

        // Toggle HUD & Close Button
        int row4Y = row3Y + btnHeight + gap + 4;
        addRenderableWidget(Button.builder(Component.literal("\ud83d\udda5\ufe0f B\u1eadt/T\u1eaft HUD"), b -> toggleHud())
            .bounds(centerX - 130, row4Y, 120, btnHeight).build());
        addRenderableWidget(Button.builder(Component.literal("\u274c \u0110\u00f3ng Menu"), b -> onClose())
            .bounds(centerX + 10, row4Y, 120, btnHeight).build());
    }

    private void morph(EntityType<?> type, String name) {
        if (this.minecraft != null && this.minecraft.player != null) {
            MorphManager.morphByType(this.minecraft.player, type, name);
            onClose();
        }
    }

    private void unmorph() {
        if (this.minecraft != null && this.minecraft.player != null) {
            MorphManager.unmorph(this.minecraft.player);
            onClose();
        }
    }

    private void giveMask() {
        if (this.minecraft != null && this.minecraft.player != null) {
            this.minecraft.player.getInventory().add(MorphManager.createMaskItem());
            onClose();
        }
    }

    private void giveVip() {
        if (this.minecraft != null) {
            UnlockAdvancementsMod.giveVipItems(this.minecraft);
            onClose();
        }
    }

    private void unlockAll() {
        if (this.minecraft != null) {
            UnlockAdvancementsMod.unlockAll(this.minecraft);
            onClose();
        }
    }

    private void addXp() {
        if (this.minecraft != null) {
            UnlockAdvancementsMod.handleXp(this.minecraft, "+10");
        }
    }

    private void toggleHud() {
        MorphHud.enabled = !MorphHud.enabled;
        if (this.minecraft != null && this.minecraft.player != null) {
            this.minecraft.player.sendSystemMessage(Component.literal(
                "\u00a76[HUD] \u00a7fTr\u1ea1ng th\u00e1i HUD tr\u00ean m\u00e0n h\u00ecnh: " +
                (MorphHud.enabled ? "\u00a7aB\u1eacT \u2714" : "\u00a7cT\u1eaeT \u2718")
            ));
        }
    }

    @Override
    public void extractRenderState(GuiGraphicsExtractor extractor, int mouseX, int mouseY, float partialTick) {
        // Translucent dark background
        extractor.fill(0, 0, this.width, this.height, 0xC8050914);

        // Header Title
        extractor.centeredText(this.font, Component.literal("\u00a76\u00a7l\u2726 MENU H\u00d3A TH\u00c2N & TI\u1ec6N \u00cdCH VIP \u2726"), this.width / 2, 12, 0xFFFFFFFF);
        extractor.centeredText(this.font, Component.literal("\u00a77Ch\u1ecdn Mob b\u00ean d\u01b0\u1edbi \u0111\u1ec3 bi\u1ebfn h\u00ecnh ngay ho\u1eb7c d\u00f9ng c\u00e1c ch\u1ee9c n\u0103ng nhanh"), this.width / 2, 26, 0xFFAAAAAA);

        super.extractRenderState(extractor, mouseX, mouseY, partialTick);
    }
}

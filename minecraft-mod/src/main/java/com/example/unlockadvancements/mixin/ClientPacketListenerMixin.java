package com.example.unlockadvancements.mixin;

import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientPacketListener;
import com.example.unlockadvancements.UnlockAdvancementsMod;

@Mixin(ClientPacketListener.class)
public class ClientPacketListenerMixin {
    @Inject(method = "sendCommand(Ljava/lang/String;)V", at = @At("HEAD"), cancellable = true)
    private void onSendCommand(String command, CallbackInfo ci) {
        if (command == null) return;
        String trimmed = command.trim();
        String lower = trimmed.toLowerCase();

        if (lower.equals("unlockall") || lower.equals("unlockadvancements") || lower.equals("alladvancements")) {
            ci.cancel();
            UnlockAdvancementsMod.LOGGER.info("Kich hoat mo khoa thanh tuu boi lenh chat: /" + trimmed);
            UnlockAdvancementsMod.unlockAll(Minecraft.getInstance());
        } else if (isModXpCommand(lower)) {
            ci.cancel();
            String arg = "";
            if (lower.startsWith("xp ")) {
                arg = trimmed.substring(3).trim();
            } else if (lower.startsWith("addxp")) {
                arg = "+" + trimmed.substring(5).trim();
            } else if (lower.startsWith("subxp")) {
                arg = "-" + trimmed.substring(5).trim();
            } else if (lower.startsWith("setxp")) {
                arg = trimmed.substring(5).trim();
            }
            UnlockAdvancementsMod.LOGGER.info("Kich hoat lenh XP: /" + trimmed);
            UnlockAdvancementsMod.handleXp(Minecraft.getInstance(), arg);
        } else if (lower.equals("vip") || lower.equals("givevip") || lower.equals("godset")) {
            ci.cancel();
            UnlockAdvancementsMod.LOGGER.info("Kich hoat lenh VIP: /" + trimmed);
            UnlockAdvancementsMod.giveVipItems(Minecraft.getInstance());
        } else if (lower.equals("menu") || lower.equals("morphmenu") || lower.equals("hub")) {
            ci.cancel();
            Minecraft mc = Minecraft.getInstance();
            mc.execute(() -> {
                mc.setScreenAndShow(new com.example.unlockadvancements.MorphMenuScreen());
            });
        } else if (lower.equals("hud") || lower.equals("togglehud")) {
            ci.cancel();
            com.example.unlockadvancements.MorphHud.enabled = !com.example.unlockadvancements.MorphHud.enabled;
            Minecraft mc = Minecraft.getInstance();
            if (mc.player != null) {
                mc.player.sendSystemMessage(net.minecraft.network.chat.Component.literal(
                    "\u00a76[HUD] \u00a7fTr\u1ea1ng th\u00e1i HUD tr\u00ean m\u00e0n h\u00ecnh: " +
                    (com.example.unlockadvancements.MorphHud.enabled ? "\u00a7aB\u1eacT \u2714" : "\u00a7cT\u1eaeT \u2718")
                ));
            }
        } else if (lower.equals("mask") || lower.equals("morphmask") || lower.equals("matna")) {
            ci.cancel();
            UnlockAdvancementsMod.LOGGER.info("Kich hoat lenh Mask: /" + trimmed);
            Minecraft mc = Minecraft.getInstance();
            if (mc.player != null) {
                mc.player.getInventory().add(com.example.unlockadvancements.MorphManager.createMaskItem());
                mc.player.sendSystemMessage(net.minecraft.network.chat.Component.literal(
                    "\u00a76\u00a7l[M\u1eb7t N\u1ea1 H\u00f3a Th\u00e2n] \u00a7a\u0110\u00e3 nh\u1eadn M\u1eb7t N\u1ea1 H\u00f3a Th\u00e2n! \u00a7f\u0110eo v\u00e0o \u0111\u1ea7u v\u00e0 nh\u1ea5p chu\u1ed9t tr\u00e1i v\u00e0o Mob \u0111\u1ec3 bi\u1ebfn th\u00e0nh h\u1ecd."
                ));
            }
        } else if (lower.startsWith("morph ") || lower.equals("morph")) {
            ci.cancel();
            Minecraft mc = Minecraft.getInstance();
            if (mc.player != null) {
                String mobName = trimmed.length() > 6 ? trimmed.substring(6).trim().toLowerCase() : "";
                if (mobName.isEmpty()) {
                    mc.player.sendSystemMessage(net.minecraft.network.chat.Component.literal(
                        "\u00a7eC\u00e1ch d\u00f9ng: \u00a7f/morph <t\u00ean mob> \u00a77(VD: /morph creeper, /morph zombie, /morph enderman, /morph warden...)"
                    ));
                } else {
                    net.minecraft.resources.Identifier id = net.minecraft.resources.Identifier.tryParse(mobName.contains(":") ? mobName : "minecraft:" + mobName);
                    if (id != null && net.minecraft.core.registries.BuiltInRegistries.ENTITY_TYPE.containsKey(id)) {
                        net.minecraft.world.entity.EntityType<?> type = net.minecraft.core.registries.BuiltInRegistries.ENTITY_TYPE.getValue(id);
                        com.example.unlockadvancements.MorphManager.morphByType(mc.player, type, mobName);
                    } else {
                        mc.player.sendSystemMessage(net.minecraft.network.chat.Component.literal(
                            "\u00a7cKh\u00f4ng t\u00ecm th\u1ea5y mob: \u00a7e" + mobName
                        ));
                    }
                }
            }
        } else if (lower.equals("unmorph")) {
            ci.cancel();
            Minecraft mc = Minecraft.getInstance();
            if (mc.player != null) {
                com.example.unlockadvancements.MorphManager.unmorph(mc.player);
            }
        }
    }

    // Only take over /xp when it uses the mod's short syntax (/xp, /xp +10, /xp -5, /xp 99);
    // vanilla forms like "/xp add <player> 10 levels" are passed through to the real command.
    private static boolean isModXpCommand(String lower) {
        if (lower.equals("xp")) return true;
        if (lower.startsWith("xp ")) {
            return lower.substring(3).trim().matches("[+-]?\\s*\\d+");
        }
        return lower.matches("(addxp|subxp|setxp)(\\s+\\d+)?");
    }
}

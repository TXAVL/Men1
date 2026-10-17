package com.example.unlockadvancements;

import net.fabricmc.api.ClientModInitializer;
import net.minecraft.client.Minecraft;
import net.minecraft.network.chat.Component;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.ServerAdvancementManager;
import net.minecraft.server.PlayerAdvancements;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.advancements.AdvancementHolder;
import net.minecraft.advancements.AdvancementProgress;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class UnlockAdvancementsMod implements ClientModInitializer {
    public static final String MOD_ID = "unlockadvancements";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    @Override
    public void onInitializeClient() {
        LOGGER.info("[UnlockAdvancements] Mod loaded! Phim Shift+7/F7 mo khoa thanh tuu. Lenh chat: /xp, /givevip, /unlockall.");
    }

    public static void unlockAll(Minecraft minecraft) {
        if (minecraft == null || minecraft.player == null) {
            return;
        }

        if (minecraft.hasSingleplayerServer() && minecraft.getSingleplayerServer() != null) {
            MinecraftServer server = minecraft.getSingleplayerServer();
            UUID playerId = minecraft.player.getUUID();
            server.execute(() -> {
                try {
                    ServerPlayer serverPlayer = server.getPlayerList().getPlayer(playerId);
                    if (serverPlayer == null) {
                        return;
                    }

                    ServerAdvancementManager advManager = server.getAdvancements();
                    PlayerAdvancements playerAdvs = serverPlayer.getAdvancements();
                    int granted = 0;

                    for (AdvancementHolder holder : advManager.getAllAdvancements()) {
                        AdvancementProgress progress = playerAdvs.getOrStartProgress(holder);
                        if (!progress.isDone()) {
                            for (String criterion : progress.getRemainingCriteria()) {
                                playerAdvs.award(holder, criterion);
                            }
                            granted++;
                        }
                    }

                    final int totalGranted = granted;
                    minecraft.execute(() -> {
                        chat(minecraft, Component.literal(
                            "§a§l[Thành Tựu] §fĐã mở khóa toàn bộ thành tựu trong game! (§e+" + totalGranted + "§f mục mới)"
                        ));
                    });
                } catch (Exception e) {
                    LOGGER.error("Loi khi mo khoa thanh tuu", e);
                    minecraft.execute(() -> {
                        chat(minecraft, Component.literal("§c§l[Lỗi] §fKhông thể mở khóa thành tựu: " + e.getMessage()));
                    });
                }
            });
        } else {
            // Multiplayer fallback
            if (minecraft.player.connection != null) {
                minecraft.player.connection.sendCommand("advancement grant @s everything");
                chat(minecraft, Component.literal(
                    "§e§l[Thành Tựu] §fĐã gửi lệnh mở khóa thành tựu tới máy chủ (/advancement grant @s everything)"
                ));
            }
        }
    }

    public static void handleXp(Minecraft minecraft, String arg) {
        if (minecraft == null || minecraft.player == null) return;

        if (minecraft.hasSingleplayerServer() && minecraft.getSingleplayerServer() != null) {
            MinecraftServer server = minecraft.getSingleplayerServer();
            UUID playerId = minecraft.player.getUUID();
            server.execute(() -> {
                ServerPlayer serverPlayer = server.getPlayerList().getPlayer(playerId);
                if (serverPlayer == null) return;

                String trimmed = arg.trim();
                if (trimmed.isEmpty()) {
                    minecraft.execute(() -> {
                        chat(minecraft, Component.literal("§6§l[XP Manager] §fCấp độ hiện tại: §a§lLevel " + serverPlayer.experienceLevel));
                        chat(minecraft, Component.literal("§e- Cộng cấp: §f/xp +<số> §7(VD: §a/xp +10§7)"));
                        chat(minecraft, Component.literal("§e- Trừ cấp:  §f/xp -<số> §7(VD: §c/xp -5§7)"));
                        chat(minecraft, Component.literal("§e- Đặt cấp:  §f/xp <số>  §7(VD: §b/xp 99§7)"));
                    });
                    return;
                }

                try {
                    int change = 0;
                    boolean isSet = false;
                    if (trimmed.startsWith("+")) {
                        change = Integer.parseInt(trimmed.substring(1).trim());
                    } else if (trimmed.startsWith("-")) {
                        change = -Integer.parseInt(trimmed.substring(1).trim());
                    } else if (trimmed.toLowerCase().startsWith("add ")) {
                        change = Integer.parseInt(trimmed.substring(4).trim());
                    } else if (trimmed.toLowerCase().startsWith("sub ")) {
                        change = -Integer.parseInt(trimmed.substring(4).trim());
                    } else if (trimmed.toLowerCase().startsWith("set ")) {
                        int target = Integer.parseInt(trimmed.substring(4).trim());
                        change = target - serverPlayer.experienceLevel;
                        isSet = true;
                    } else {
                        int target = Integer.parseInt(trimmed);
                        change = target - serverPlayer.experienceLevel;
                        isSet = true;
                    }

                    serverPlayer.giveExperienceLevels(change);
                    final int newLevel = serverPlayer.experienceLevel;
                    final int delta = change;
                    final boolean wasSet = isSet;

                    minecraft.execute(() -> {
                        if (wasSet) {
                            chat(minecraft, Component.literal("§a§l[XP Manager] §fĐã đặt cấp độ thành: §e§lLevel " + newLevel));
                        } else if (delta >= 0) {
                            chat(minecraft, Component.literal("§a§l[XP Manager] §fĐã cộng §e+" + delta + "§f cấp! Cấp độ mới: §a§lLevel " + newLevel));
                        } else {
                            chat(minecraft, Component.literal("§c§l[XP Manager] §fĐã trừ §c" + delta + "§f cấp! Cấp độ mới: §a§lLevel " + newLevel));
                        }
                    });
                } catch (NumberFormatException e) {
                    minecraft.execute(() -> {
                        chat(minecraft, Component.literal("§c§l[Lỗi] §fSố cấp độ không hợp lệ: " + trimmed));
                    });
                }
            });
        } else {
            // Multiplayer fallback
            if (minecraft.player.connection != null) {
                String trimmed = arg.trim().replace(" ", "");
                if (trimmed.isEmpty()) {
                    minecraft.player.connection.sendCommand("experience query @s levels");
                } else if (trimmed.startsWith("+")) {
                    minecraft.player.connection.sendCommand("experience add @s " + trimmed.substring(1) + " levels");
                } else if (trimmed.startsWith("-")) {
                    minecraft.player.connection.sendCommand("experience add @s " + trimmed + " levels");
                } else {
                    minecraft.player.connection.sendCommand("experience set @s " + trimmed + " levels");
                }
            }
        }
    }

    private static void applyEnchant(net.minecraft.core.HolderLookup.RegistryLookup<net.minecraft.world.item.enchantment.Enchantment> reg, ItemStack stack, String id, int level) {
        if (reg != null) {
            reg.get(net.minecraft.resources.ResourceKey.create(net.minecraft.core.registries.Registries.ENCHANTMENT, net.minecraft.resources.Identifier.parse(id)))
               .ifPresent(h -> stack.enchant(h, level));
        }
    }

    public static void giveVipItems(Minecraft minecraft) {
        if (minecraft == null || minecraft.player == null) return;

        if (minecraft.hasSingleplayerServer() && minecraft.getSingleplayerServer() != null) {
            MinecraftServer server = minecraft.getSingleplayerServer();
            UUID playerId = minecraft.player.getUUID();
            server.execute(() -> {
                ServerPlayer serverPlayer = server.getPlayerList().getPlayer(playerId);
                if (serverPlayer == null) return;

                var reg = server.registryAccess().lookupOrThrow(net.minecraft.core.registries.Registries.ENCHANTMENT);
                var inv = serverPlayer.getInventory();

                // 1. Sword
                ItemStack sword = new ItemStack(Items.NETHERITE_SWORD);
                applyEnchant(reg, sword, "minecraft:sharpness", 5);
                applyEnchant(reg, sword, "minecraft:looting", 3);
                applyEnchant(reg, sword, "minecraft:fire_aspect", 2);
                applyEnchant(reg, sword, "minecraft:sweeping_edge", 3);
                applyEnchant(reg, sword, "minecraft:knockback", 2);
                applyEnchant(reg, sword, "minecraft:unbreaking", 3);
                applyEnchant(reg, sword, "minecraft:mending", 1);
                inv.add(sword);

                // 2. Mace (1.21)
                ItemStack mace = new ItemStack(Items.MACE);
                applyEnchant(reg, mace, "minecraft:density", 5);
                applyEnchant(reg, mace, "minecraft:breach", 4);
                applyEnchant(reg, mace, "minecraft:wind_burst", 3);
                applyEnchant(reg, mace, "minecraft:unbreaking", 3);
                applyEnchant(reg, mace, "minecraft:mending", 1);
                inv.add(mace);

                // 3. Pickaxe
                ItemStack pick = new ItemStack(Items.NETHERITE_PICKAXE);
                applyEnchant(reg, pick, "minecraft:efficiency", 5);
                applyEnchant(reg, pick, "minecraft:fortune", 3);
                applyEnchant(reg, pick, "minecraft:unbreaking", 3);
                applyEnchant(reg, pick, "minecraft:mending", 1);
                inv.add(pick);

                // 4. Axe
                ItemStack axe = new ItemStack(Items.NETHERITE_AXE);
                applyEnchant(reg, axe, "minecraft:efficiency", 5);
                applyEnchant(reg, axe, "minecraft:sharpness", 5);
                applyEnchant(reg, axe, "minecraft:unbreaking", 3);
                applyEnchant(reg, axe, "minecraft:mending", 1);
                inv.add(axe);

                // 5. Bow & Crossbow
                ItemStack bow = new ItemStack(Items.BOW);
                applyEnchant(reg, bow, "minecraft:power", 5);
                applyEnchant(reg, bow, "minecraft:flame", 1);
                applyEnchant(reg, bow, "minecraft:infinity", 1);
                applyEnchant(reg, bow, "minecraft:punch", 2);
                applyEnchant(reg, bow, "minecraft:unbreaking", 3);
                inv.add(bow);

                ItemStack xbow = new ItemStack(Items.CROSSBOW);
                applyEnchant(reg, xbow, "minecraft:quick_charge", 3);
                applyEnchant(reg, xbow, "minecraft:multishot", 1);
                applyEnchant(reg, xbow, "minecraft:unbreaking", 3);
                applyEnchant(reg, xbow, "minecraft:mending", 1);
                inv.add(xbow);

                // 6. Trident
                ItemStack trident = new ItemStack(Items.TRIDENT);
                applyEnchant(reg, trident, "minecraft:loyalty", 3);
                applyEnchant(reg, trident, "minecraft:channeling", 1);
                applyEnchant(reg, trident, "minecraft:impaling", 5);
                applyEnchant(reg, trident, "minecraft:unbreaking", 3);
                applyEnchant(reg, trident, "minecraft:mending", 1);
                inv.add(trident);

                // 7. Full Armor
                ItemStack boots = new ItemStack(Items.NETHERITE_BOOTS);
                applyEnchant(reg, boots, "minecraft:protection", 4);
                applyEnchant(reg, boots, "minecraft:feather_falling", 4);
                applyEnchant(reg, boots, "minecraft:depth_strider", 3);
                applyEnchant(reg, boots, "minecraft:unbreaking", 3);
                applyEnchant(reg, boots, "minecraft:mending", 1);
                inv.add(boots);

                ItemStack legs = new ItemStack(Items.NETHERITE_LEGGINGS);
                applyEnchant(reg, legs, "minecraft:protection", 4);
                applyEnchant(reg, legs, "minecraft:swift_sneak", 3);
                applyEnchant(reg, legs, "minecraft:unbreaking", 3);
                applyEnchant(reg, legs, "minecraft:mending", 1);
                inv.add(legs);

                ItemStack chest = new ItemStack(Items.NETHERITE_CHESTPLATE);
                applyEnchant(reg, chest, "minecraft:protection", 4);
                applyEnchant(reg, chest, "minecraft:thorns", 3);
                applyEnchant(reg, chest, "minecraft:unbreaking", 3);
                applyEnchant(reg, chest, "minecraft:mending", 1);
                inv.add(chest);

                ItemStack helm = new ItemStack(Items.NETHERITE_HELMET);
                applyEnchant(reg, helm, "minecraft:protection", 4);
                applyEnchant(reg, helm, "minecraft:respiration", 3);
                applyEnchant(reg, helm, "minecraft:aqua_affinity", 1);
                applyEnchant(reg, helm, "minecraft:unbreaking", 3);
                applyEnchant(reg, helm, "minecraft:mending", 1);
                inv.add(helm);

                // 8. Elytra & Shield
                ItemStack elytra = new ItemStack(Items.ELYTRA);
                applyEnchant(reg, elytra, "minecraft:unbreaking", 3);
                applyEnchant(reg, elytra, "minecraft:mending", 1);
                inv.add(elytra);

                ItemStack shield = new ItemStack(Items.SHIELD);
                applyEnchant(reg, shield, "minecraft:unbreaking", 3);
                applyEnchant(reg, shield, "minecraft:mending", 1);
                inv.add(shield);

                // 9. Consumables & Rare Blocks
                inv.add(new ItemStack(Items.ENCHANTED_GOLDEN_APPLE, 64));
                inv.add(new ItemStack(Items.TOTEM_OF_UNDYING, 64));
                inv.add(new ItemStack(Items.FIREWORK_ROCKET, 64));
                inv.add(new ItemStack(Items.WIND_CHARGE, 64));
                inv.add(new ItemStack(Items.ENDER_PEARL, 16));
                inv.add(new ItemStack(Items.GOLDEN_CARROT, 64));
                inv.add(new ItemStack(Items.DIAMOND_BLOCK, 64));
                inv.add(new ItemStack(Items.NETHERITE_BLOCK, 64));
                inv.add(new ItemStack(Items.BEACON, 64));
                inv.add(new ItemStack(Items.NETHER_STAR, 64));
                inv.add(new ItemStack(Items.HEAVY_CORE, 16));
                inv.add(new ItemStack(Items.CRAFTER, 64));
                inv.add(new ItemStack(Items.ARROW, 64));

                minecraft.execute(() -> {
                    chat(minecraft, Component.literal("§6§l[VIP] §fĐã nhận trọn bộ trang bị Max Phụ Ma & toàn bộ vật phẩm VIP vào túi đồ!"));
                });
            });
        } else {
            chat(minecraft, Component.literal("§c§l[VIP] §fChỉ dùng được trong thế giới chơi đơn (singleplayer)."));
        }
    }

    private static void chat(Minecraft minecraft, Component message) {
        if (minecraft != null && minecraft.player != null) {
            minecraft.player.sendSystemMessage(message);
        }
    }
}
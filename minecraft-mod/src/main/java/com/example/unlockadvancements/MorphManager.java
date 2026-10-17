package com.example.unlockadvancements;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import net.minecraft.client.Minecraft;
import net.minecraft.client.player.LocalPlayer;
import net.minecraft.core.component.DataComponents;
import net.minecraft.core.particles.ParticleTypes;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.resources.Identifier;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.*;
import net.minecraft.world.entity.monster.*;
import net.minecraft.world.entity.monster.illager.AbstractIllager;
import net.minecraft.world.entity.monster.piglin.AbstractPiglin;
import net.minecraft.world.entity.monster.warden.Warden;
import net.minecraft.world.entity.boss.wither.WitherBoss;
import net.minecraft.world.entity.boss.enderdragon.EnderDragon;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.Items;
import net.minecraft.world.level.Level;

public class MorphManager {
    // True only while LevelExtractor extracts the world's visible entities (the only safe place to swap the player model)
    public static volatile boolean isExtractingWorldEntities = false;
    // Current morph state per player
    private static final Map<UUID, EntityType<?>> playerMorphMap = new ConcurrentHashMap<>();
    private static final Map<UUID, String> playerMorphNameMap = new ConcurrentHashMap<>();

    // Client-side dummy entity for model rendering
    private static final Map<UUID, LivingEntity> clientDummyMap = new ConcurrentHashMap<>();
    private static final Map<UUID, EntityType<?>> clientDummyTypeMap = new ConcurrentHashMap<>();
    // Mob types whose model failed to render: keep the player model instead of retrying every frame
    private static final Set<EntityType<?>> renderFailedTypes = Collections.newSetFromMap(new ConcurrentHashMap<>());

    // Smart mob suspicion tracking: Mob UUID -> ticks suspecting (0 to 100 = 5 seconds)
    private static final Map<UUID, Integer> smartMobSuspicion = new ConcurrentHashMap<>();
    private static final Set<UUID> alertedSmartMobs = Collections.newSetFromMap(new ConcurrentHashMap<>());

    // Mask identification
    public static boolean isWearingMask(Player player) {
        if (player == null) return false;
        ItemStack head = player.getItemBySlot(EquipmentSlot.HEAD);
        ItemStack main = player.getMainHandItem();
        ItemStack off = player.getOffhandItem();
        return isMaskItem(head) || isMaskItem(main) || isMaskItem(off);
    }

    public static boolean isMaskItem(ItemStack stack) {
        if (stack == null || stack.isEmpty()) return false;
        if (stack.is(Items.CARVED_PUMPKIN)) return true;
        Component customName = stack.get(DataComponents.CUSTOM_NAME);
        if (customName != null) {
            String str = customName.getString().toLowerCase();
            return str.contains("m\u1eb7t n\u1ea1") || str.contains("mask") || str.contains("h\u00f3a th\u00e2n") || str.contains("disguise");
        }
        return false;
    }

    public static boolean isMorphed(Player player) {
        if (player == null) return false;
        return playerMorphMap.containsKey(player.getUUID());
    }

    public static EntityType<?> getMorphedType(Player player) {
        if (player == null) return null;
        return playerMorphMap.get(player.getUUID());
    }

    public static String getMorphedName(Player player) {
        if (player == null) return "";
        return playerMorphNameMap.getOrDefault(player.getUUID(), "");
    }

    // Morph the player into a target entity
    public static void morph(Player player, LivingEntity target) {
        if (player == null || target == null || target instanceof Player) return;
        EntityType<?> type = target.getType();
        String mobName = target.getName().getString();

        playerMorphMap.put(player.getUUID(), type);
        playerMorphNameMap.put(player.getUUID(), mobName);
        clearClientDummy(player.getUUID());

        // Effects
        Level level = player.level();
        if (level.isClientSide()) {
            spawnMorphPoof(player);
            level.playLocalSound(player.getX(), player.getY(), player.getZ(),
                SoundEvents.ILLUSIONER_MIRROR_MOVE, SoundSource.PLAYERS, 1.0f, 1.0f, false);
            if (player instanceof LocalPlayer localPlayer) {
                localPlayer.sendOverlayMessage(Component.literal(
                    "\u00a7a\u00a7l\ud83c\udfad [H\u00f3a Th\u00e2n] \u00a7f\u0110\u00e3 bi\u1ebfn th\u00e0nh \u00a7e" + mobName + "\u00a7f! \u00a77(Shift + Chu\u1ed9t tr\u00e1i \u0111\u1ec3 tr\u1edf l\u1ea1i)"
                ));
                localPlayer.sendSystemMessage(Component.literal(
                    "\u00a76\u00a7l[M\u1eb7t N\u1ea1 H\u00f3a Th\u00e2n] \u00a7aB\u1ea1n \u0111\u00e3 h\u00f3a th\u00e2n th\u00e0nh \u00a7e" + mobName + "\u00a7a!\n" +
                    "\u00a7f- \u00a7aQu\u00e1i ngu ng\u1ed1c (Zombie, Creeper, Nh\u1ec7n...): \u00a72T\u01b0\u1edfng b\u1ea1n l\u00e0 \u0111\u1ed3ng lo\u1ea1i, kh\u00f4ng t\u1ea5n c\u00f4ng!\n" +
                    "\u00a7f- \u00a7cQu\u00e1i th\u00f4ng minh (Enderman, Ph\u00f9 Th\u1ee7y, Warden...): \u00a76S\u1ebd nghi ng\u1edd & ph\u00e1t hi\u1ec7n sau 5 gi\u00e2y!"
                ));
            }
        }
    }

    public static void morphByType(Player player, EntityType<?> type, String displayName) {
        if (player == null || type == null) return;
        playerMorphMap.put(player.getUUID(), type);
        playerMorphNameMap.put(player.getUUID(), displayName);
        clearClientDummy(player.getUUID());

        Level level = player.level();
        if (level.isClientSide()) {
            spawnMorphPoof(player);
            level.playLocalSound(player.getX(), player.getY(), player.getZ(),
                SoundEvents.ILLUSIONER_MIRROR_MOVE, SoundSource.PLAYERS, 1.0f, 1.0f, false);
            if (player instanceof LocalPlayer localPlayer) {
                localPlayer.sendOverlayMessage(Component.literal(
                    "\u00a7a\u00a7l\ud83c\udfad [H\u00f3a Th\u00e2n] \u00a7f\u0110\u00e3 bi\u1ebfn th\u00e0nh \u00a7e" + displayName
                ));
            }
        }
    }

    // Unmorph back to human
    public static void unmorph(Player player) {
        if (player == null) return;
        if (!playerMorphMap.containsKey(player.getUUID())) return;

        playerMorphMap.remove(player.getUUID());
        playerMorphNameMap.remove(player.getUUID());
        clearClientDummy(player.getUUID());
        smartMobSuspicion.clear();
        alertedSmartMobs.clear();

        Level level = player.level();
        if (level.isClientSide()) {
            spawnMorphPoof(player);
            level.playLocalSound(player.getX(), player.getY(), player.getZ(),
                SoundEvents.ZOMBIE_VILLAGER_CONVERTED, SoundSource.PLAYERS, 1.0f, 1.2f, false);
            if (player instanceof LocalPlayer localPlayer) {
                localPlayer.sendOverlayMessage(Component.literal(
                    "\u00a7e\u00a7l\ud83c\udfad [H\u00f3a Th\u00e2n] \u00a7f\u0110\u00e3 tr\u1edf v\u1ec1 h\u00ecnh d\u1ea1ng con ng\u01b0\u1eddi b\u00ecnh th\u01b0\u1eddng!"
                ));
            }
        }
    }

    public static int getMaxSuspicion(Player player) {
        if (player == null || !isMorphed(player)) return 0;
        int max = 0;
        for (int ticks : smartMobSuspicion.values()) {
            if (ticks > max) max = ticks;
        }
        return max;
    }

    public static boolean isAlerted(Player player) {
        if (player == null || !isMorphed(player)) return false;
        return !alertedSmartMobs.isEmpty();
    }

    private static void spawnMorphPoof(Player player) {
        Level level = player.level();
        for (int i = 0; i < 20; i++) {
            double rx = player.getX() + (Math.random() - 0.5) * 1.5;
            double ry = player.getY() + Math.random() * 2.0;
            double rz = player.getZ() + (Math.random() - 0.5) * 1.5;
            level.addParticle(ParticleTypes.POOF, rx, ry, rz, 0.0, 0.05, 0.0);
        }
    }

    // Client dummy management for rendering
    public static LivingEntity getClientDummy(Player player) {
        if (player == null) return null;
        EntityType<?> type = playerMorphMap.get(player.getUUID());
        if (type == null || renderFailedTypes.contains(type)) return null;

        LivingEntity dummy = clientDummyMap.get(player.getUUID());
        EntityType<?> cachedType = clientDummyTypeMap.get(player.getUUID());

        if (dummy == null || cachedType != type || dummy.level() != player.level()) {
            try {
                Entity newEntity = type.create(player.level(), EntitySpawnReason.LOAD);
                if (newEntity instanceof LivingEntity livingDummy) {
                    dummy = livingDummy;
                    dummy.setId(player.getId());
                    clientDummyMap.put(player.getUUID(), dummy);
                    clientDummyTypeMap.put(player.getUUID(), type);
                } else {
                    renderFailedTypes.add(type);
                    return null;
                }
            } catch (Throwable t) {
                renderFailedTypes.add(type);
                return null;
            }
        }
        return dummy;
    }

    public static void syncDummyWithPlayer(LivingEntity dummy, Player player) {
        if (dummy == null || player == null) return;
        dummy.setId(player.getId());
        dummy.setPos(player.getX(), player.getY(), player.getZ());
        dummy.xo = player.xo;
        dummy.yo = player.yo;
        dummy.zo = player.zo;
        dummy.setYRot(player.getYRot());
        dummy.setXRot(player.getXRot());
        dummy.yRotO = player.yRotO;
        dummy.xRotO = player.xRotO;
        dummy.yBodyRot = player.yBodyRot;
        dummy.yBodyRotO = player.yBodyRotO;
        dummy.yHeadRot = player.yHeadRot;
        dummy.yHeadRotO = player.yHeadRotO;
        dummy.tickCount = player.tickCount;
        dummy.setOnGround(player.onGround());
        dummy.setPose(player.getPose());
        dummy.setShiftKeyDown(player.isShiftKeyDown());
        dummy.setSprinting(player.isSprinting());
        dummy.setSwimming(player.isSwimming());

        try {
            dummy.walkAnimation.setSpeed(player.walkAnimation.speed());
        } catch (Throwable ignored) {}

        try {
            for (EquipmentSlot slot : EquipmentSlot.values()) {
                dummy.setItemSlot(slot, player.getItemBySlot(slot));
            }
        } catch (Throwable ignored) {}
    }

    public static void markRenderFailed(Player player, EntityType<?> type) {
        renderFailedTypes.add(type);
        if (player != null) clearClientDummy(player.getUUID());
    }

    public static void clearClientDummy(UUID uuid) {
        clientDummyMap.remove(uuid);
        clientDummyTypeMap.remove(uuid);
    }

    // ==========================================
    // MOB AI / INTELLIGENCE & SUSPICION SYSTEM
    // ==========================================

    // Smart mobs check
    public static boolean isSmartMob(Mob mob) {
        if (mob == null) return false;
        if (mob instanceof Enderman || mob instanceof Witch) return true;
        if (mob instanceof AbstractIllager) return true; // Evoker, Vindicator, Pillager, Illusioner
        if (mob instanceof Ravager) return true;
        if (mob instanceof Warden) return true;
        if (mob instanceof AbstractPiglin) return true; // Piglin, Piglin Brute
        if (mob instanceof Guardian) return true; // Guardian, Elder Guardian
        if (mob instanceof WitherBoss) return true;
        if (mob instanceof EnderDragon) return true;
        return false;
    }

    // Called when a mob tries to target or attack a player
    public static boolean shouldMobIgnore(Mob mob, Player player) {
        if (mob == null || player == null) return false;
        if (!isMorphed(player)) return false;

        UUID mobUUID = mob.getUUID();

        // 1. Stupid Mobs: Zombie, Skeleton, Creeper, Spider, Slime, Silverfish, etc.
        // They 100% believe the player is their comrade and NEVER attack!
        if (!isSmartMob(mob)) {
            return true;
        }

        // 2. Smart Mobs: Enderman, Witch, Evoker, Warden, Piglin Brute, etc.
        // If they have completed their 5s (100 ticks) detection, they attack!
        if (alertedSmartMobs.contains(mobUUID)) {
            return false; // Already alerted, attack!
        }

        // If not yet alerted, they are still observing / suspecting (ignore target for now)
        return true;
    }

    // Tick logic for smart mobs encountering a morphed player.
    // Runs on the (integrated) server only: the client copy of a mob has the same UUID and would double-count.
    public static void tickMobSuspicion(Mob mob) {
        if (mob == null || playerMorphMap.isEmpty()) return;

        Level level = mob.level();
        if (level.isClientSide() || !isSmartMob(mob)) return;

        UUID mobUUID = mob.getUUID();

        // If already alerted, no need to track countdown
        if (alertedSmartMobs.contains(mobUUID)) {
            return;
        }

        // Find nearest player
        Player player = level.getNearestPlayer(mob, 14.0);
        if (player == null || !isMorphed(player)) {
            // Player left range: suspicion slowly resets
            Integer current = smartMobSuspicion.get(mobUUID);
            if (current != null) {
                int next = current - 2;
                if (next > 0) smartMobSuspicion.put(mobUUID, next);
                else smartMobSuspicion.remove(mobUUID);
            }
            return;
        }

        // Check line of sight
        if (!mob.hasLineOfSight(player)) {
            return;
        }

        // Increment suspicion
        int ticks = smartMobSuspicion.getOrDefault(mobUUID, 0) + 1;
        smartMobSuspicion.put(mobUUID, ticks);

        // Spawn suspicion particles at mob's head
        if (ticks % 10 == 0 && level instanceof ServerLevel serverLevel) {
            serverLevel.sendParticles(ParticleTypes.SMOKE,
                mob.getX(), mob.getY() + mob.getEyeHeight() + 0.3, mob.getZ(),
                2, 0.1, 0.05, 0.1, 0.01);
        }

        // Warning sound & Action Bar countdown every second (20 ticks)
        if (ticks % 20 == 0 && ticks < 100) {
            int secondsLeft = (100 - ticks) / 20;
            level.playSound(null, mob.getX(), mob.getY(), mob.getZ(),
                SoundEvents.WARDEN_SNIFF, SoundSource.HOSTILE, 0.8f, 1.2f);
            sendOverlay(player, Component.literal(
                "§6⚠️ [Nghi Ngờ] §e" + mob.getName().getString() +
                " §fđang quan sát & nghi ngờ bạn... (§c" + secondsLeft + "s§f)"
            ));
        }

        // Reached 5.0 seconds (100 ticks): Impostor detected!
        if (ticks >= 100) {
            alertedSmartMobs.add(mobUUID);
            mob.setTarget(player);

            level.playSound(null, mob.getX(), mob.getY(), mob.getZ(),
                SoundEvents.ELDER_GUARDIAN_CURSE, SoundSource.HOSTILE, 1.0f, 1.0f);
            if (level instanceof ServerLevel serverLevel) {
                serverLevel.sendParticles(ParticleTypes.ANGRY_VILLAGER,
                    mob.getX(), mob.getY() + mob.getEyeHeight() + 0.4, mob.getZ(),
                    15, 0.5, 0.2, 0.5, 0.1);
            }
            sendOverlay(player, Component.literal(
                "§c§l🚨 [BỊ PHÁT HIỆN!] §e" + mob.getName().getString() +
                " §cđã nhận diện bạn không phải đồng loại!"
            ));
        }
    }

    private static void sendOverlay(Player player, Component message) {
        if (player instanceof ServerPlayer serverPlayer) {
            serverPlayer.sendSystemMessage(message, true);
        } else {
            player.sendOverlayMessage(message);
        }
    }

    // Give player the Disguise Mask item
    public static ItemStack createMaskItem() {
        ItemStack mask = new ItemStack(Items.CARVED_PUMPKIN);
        mask.set(DataComponents.CUSTOM_NAME, Component.literal("\u00a76\u2726 M\u1eb7t N\u1ea1 H\u00f3a Th\u00e2n Bi\u1ebfn H\u00ecnh \u2726"));
        return mask;
    }
}

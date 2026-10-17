import java.io.File;
import java.util.Map;
import net.minecraft.nbt.*;

public class EditPlayerEnchants {
    private static CompoundTag createEnchantedItem(byte slot, String id, int count, Map<String, Integer> enchants, String customName) {
        CompoundTag item = new CompoundTag();
        item.putByte("Slot", slot);
        item.putString("id", id);
        item.putInt("count", count);

        CompoundTag components = new CompoundTag();
        if (enchants != null && !enchants.isEmpty()) {
            CompoundTag enchantTag = new CompoundTag();
            CompoundTag levels = new CompoundTag();
            for (Map.Entry<String, Integer> entry : enchants.entrySet()) {
                levels.putInt(entry.getKey(), entry.getValue());
            }
            enchantTag.put("levels", levels);
            components.put("minecraft:enchantments", enchantTag);
        }

        if (customName != null && !customName.isEmpty()) {
            components.putString("minecraft:custom_name", "\"" + customName + "\"");
        }

        if (!components.isEmpty()) {
            item.put("components", components);
        }
        return item;
    }

    public static void main(String[] args) throws Exception {
        String worldDir = args[0];
        File playerFile = new File(worldDir, "players/data/75c846b7-a779-3d50-b2fb-5ab042cb78f4.dat");
        if (!playerFile.exists()) {
            System.out.println("Player file not found: " + playerFile);
            return;
        }

        CompoundTag playerTag = NbtIo.readCompressed(playerFile.toPath(), net.minecraft.nbt.NbtAccounter.unlimitedHeap());
        playerTag.putInt("XpLevel", 99);
        playerTag.putFloat("XpP", 0.0f);
        playerTag.putInt("XpTotal", 14194);
        playerTag.putInt("Score", 14194);
        playerTag.putFloat("Health", 20.0f);
        playerTag.putInt("foodLevel", 20);

        ListTag inv = new ListTag();

        // 1. Hotbar (Slots 0 - 8)
        // Slot 0: Netherite Sword Max
        inv.add(createEnchantedItem((byte)0, "minecraft:netherite_sword", 1, Map.of(
            "minecraft:sharpness", 5,
            "minecraft:looting", 3,
            "minecraft:fire_aspect", 2,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1,
            "minecraft:sweeping_edge", 3,
            "minecraft:knockback", 2
        ), "§b✦ Thánh Kiếm Netherite VIP ✦"));

        // Slot 1: Netherite Pickaxe Max
        inv.add(createEnchantedItem((byte)1, "minecraft:netherite_pickaxe", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:fortune", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§6✦ Thần Cúp Khai Khoáng VIP ✦"));

        // Slot 2: Netherite Axe Max
        inv.add(createEnchantedItem((byte)2, "minecraft:netherite_axe", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:sharpness", 5,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§c✦ Chiến Rìu Bổ Củi VIP ✦"));

        // Slot 3: Netherite Shovel Max (Silk Touch)
        inv.add(createEnchantedItem((byte)3, "minecraft:netherite_shovel", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:silk_touch", 1,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§a✦ Siêu Xẻng Đào Đất VIP ✦"));

        // Slot 4: Heavy Mace Max (Vũ khí Chùy mới nhất!)
        inv.add(createEnchantedItem((byte)4, "minecraft:mace", 1, Map.of(
            "minecraft:density", 5,
            "minecraft:breach", 4,
            "minecraft:wind_burst", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§d✦ Lôi Thần Chùy Mace VIP ✦"));

        // Slot 5: Bow Max
        inv.add(createEnchantedItem((byte)5, "minecraft:bow", 1, Map.of(
            "minecraft:power", 5,
            "minecraft:flame", 1,
            "minecraft:infinity", 1,
            "minecraft:punch", 2,
            "minecraft:unbreaking", 3
        ), "§e✦ Thần Cung Hỏa Diệm VIP ✦"));

        // Slot 6: Trident Max
        inv.add(createEnchantedItem((byte)6, "minecraft:trident", 1, Map.of(
            "minecraft:loyalty", 3,
            "minecraft:channeling", 1,
            "minecraft:impaling", 5,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§3✦ Hải Vương Đinh Ba Trident VIP ✦"));

        // Slot 7: Crossbow Max
        inv.add(createEnchantedItem((byte)7, "minecraft:crossbow", 1, Map.of(
            "minecraft:quick_charge", 3,
            "minecraft:multishot", 1,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§9✦ Nỏ Thần Bắn Tỉa VIP ✦"));

        // Slot 8: Táo vàng Enchant x64
        inv.add(createEnchantedItem((byte)8, "minecraft:enchanted_golden_apple", 64, null, "§6Táo Vàng Phù Phép Bất Tử"));

        // 2. Armor Slots (100 - 103)
        // Boots
        inv.add(createEnchantedItem((byte)100, "minecraft:netherite_boots", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:feather_falling", 4,
            "minecraft:depth_strider", 3,
            "minecraft:soul_speed", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§5✦ Giày Netherite Vua Tốc Độ ✦"));

        // Leggings
        inv.add(createEnchantedItem((byte)101, "minecraft:netherite_leggings", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:swift_sneak", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§5✦ Quần Netherite Bất Hoại ✦"));

        // Chestplate
        inv.add(createEnchantedItem((byte)102, "minecraft:netherite_chestplate", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:thorns", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§5✦ Áo Giáp Netherite Gai Thần ✦"));

        // Helmet
        inv.add(createEnchantedItem((byte)103, "minecraft:netherite_helmet", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:respiration", 3,
            "minecraft:aqua_affinity", 1,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§5✦ Mũ Netherite Thủy Thần ✦"));

        // 3. Offhand (-106)
        inv.add(createEnchantedItem((byte)-106, "minecraft:totem_of_undying", 64, null, "§eTotem Bất Tử"));

        // 4. Main Inventory Slots (9 - 35)
        // Slot 9: Cánh cứng Elytra
        inv.add(createEnchantedItem((byte)9, "minecraft:elytra", 1, Map.of(
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§b✦ Đôi Cánh Elytra Vĩnh Cửu ✦"));

        // Slot 10: Pháo hoa bay x64
        inv.add(createEnchantedItem((byte)10, "minecraft:firework_rocket", 64, null, null));

        // Slot 11: Bóng gió Wind Charge x64
        inv.add(createEnchantedItem((byte)11, "minecraft:wind_charge", 64, null, "§bBóng Gió Phong Thần x64"));

        // Slot 12: Ngọc Ender x16
        inv.add(createEnchantedItem((byte)12, "minecraft:ender_pearl", 16, null, null));

        // Slot 13: Cà rốt vàng x64
        inv.add(createEnchantedItem((byte)13, "minecraft:golden_carrot", 64, null, null));

        // Slot 14: Đèn hiệu Beacon x4
        inv.add(createEnchantedItem((byte)14, "minecraft:beacon", 4, null, null));

        // Slot 15: Khối Netherite x64
        inv.add(createEnchantedItem((byte)15, "minecraft:netherite_block", 64, null, null));

        // Slot 16: Khối Kim Cương x64
        inv.add(createEnchantedItem((byte)16, "minecraft:diamond_block", 64, null, null));

        // Slot 17: Khối Ngọc Lục Bảo x64
        inv.add(createEnchantedItem((byte)17, "minecraft:emerald_block", 64, null, null));

        // Slot 18: Sao Nether x16
        inv.add(createEnchantedItem((byte)18, "minecraft:nether_star", 16, null, null));

        // Slot 19: Lõi nặng Heavy Core x4
        inv.add(createEnchantedItem((byte)19, "minecraft:heavy_core", 4, null, null));

        // Slot 20: Trứng Rồng Dragon Egg x1
        inv.add(createEnchantedItem((byte)20, "minecraft:dragon_egg", 1, null, "§5Trứng Rồng Ender"));

        // Slot 21: Chai kinh nghiệm x64
        inv.add(createEnchantedItem((byte)21, "minecraft:experience_bottle", 64, null, null));

        // Slot 22: Khiên Shield Max
        inv.add(createEnchantedItem((byte)22, "minecraft:shield", 1, Map.of(
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "§6✦ Khiên Kim Cang VIP ✦"));

        // Slot 23: Hộp Shulker x16
        inv.add(createEnchantedItem((byte)23, "minecraft:shulker_box", 16, null, null));

        // Slot 24: Máy chế tạo Crafter x16
        inv.add(createEnchantedItem((byte)24, "minecraft:crafter", 16, null, null));

        // Slot 25: 1 Mũi tên (Dùng chung với Cung Infinity)
        inv.add(createEnchantedItem((byte)25, "minecraft:arrow", 64, null, null));

        playerTag.put("Inventory", inv);
        NbtIo.writeCompressed(playerTag, playerFile.toPath());
        System.out.println("DA PHU MA MAX TOAN BO DO VA NHET FULL KHO ITEMS VIP THANH CONG!");
    }
}

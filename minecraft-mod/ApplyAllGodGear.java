import java.io.File;
import java.util.LinkedHashMap;
import java.util.Map;
import net.minecraft.nbt.*;

public class ApplyAllGodGear {

    private static CompoundTag createItem(byte slot, String id, int count, Map<String, Integer> enchants, String customName) {
        CompoundTag item = new CompoundTag();
        item.putByte("Slot", slot);
        item.putString("id", id);
        item.putInt("count", count);

        CompoundTag components = new CompoundTag();

        if (enchants != null && !enchants.isEmpty()) {
            CompoundTag enchantTag = new CompoundTag();
            for (Map.Entry<String, Integer> entry : enchants.entrySet()) {
                enchantTag.putInt(entry.getKey(), entry.getValue());
            }
            components.put("minecraft:enchantments", enchantTag);
        }

        if (customName != null && !customName.isEmpty()) {
            // In 1.20.5+ / 26.3, JSON text component or plain JSON string is valid for CUSTOM_NAME
            components.putString("minecraft:custom_name", "\"" + customName + "\"");
        }

        if (!components.isEmpty()) {
            item.put("components", components);
        }

        return item;
    }

    public static void main(String[] args) throws Exception {
        String worldDir = args.length > 0 ? args[0] : "C:\\Users\\admin\\AppData\\Roaming\\.tlauncher\\legacy\\Minecraft\\game\\saves\\abctest";
        File playerFile = new File(worldDir, "players/data/75c846b7-a779-3d50-b2fb-5ab042cb78f4.dat");
        if (!playerFile.exists()) {
            System.err.println("Player file not found: " + playerFile);
            return;
        }

        CompoundTag playerTag = NbtIo.readCompressed(playerFile.toPath(), NbtAccounter.unlimitedHeap());

        // Level & Stats
        playerTag.putInt("XpLevel", 99);
        playerTag.putFloat("XpP", 0.0f);
        playerTag.putInt("XpTotal", 14194);
        playerTag.putInt("Score", 14194);
        playerTag.putFloat("Health", 20.0f);
        playerTag.putInt("foodLevel", 20);
        playerTag.putFloat("foodSaturationLevel", 20.0f);
        playerTag.putByte("Invulnerable", (byte) 1);

        // ==========================================
        // 1. MAIN INVENTORY & ARMOR & OFFHAND
        // ==========================================
        ListTag inv = new ListTag();

        // --- Hotbar (0 - 8) ---
        // Slot 0: Netherite Sword God Tier
        inv.add(createItem((byte) 0, "minecraft:netherite_sword", 1, Map.of(
            "minecraft:sharpness", 5,
            "minecraft:smite", 5,
            "minecraft:bane_of_arthropods", 5,
            "minecraft:looting", 3,
            "minecraft:fire_aspect", 2,
            "minecraft:sweeping_edge", 3,
            "minecraft:knockback", 2,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7b\u2726 Th\u00e1nh Ki\u1ebfm Netherite VIP \u2726"));

        // Slot 1: Netherite Pickaxe Fortune Max
        inv.add(createItem((byte) 1, "minecraft:netherite_pickaxe", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:fortune", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a76\u2726 Th\u1ea7n C\u00fap Khai Kho\u00e1ng Fortune VIP \u2726"));

        // Slot 2: Netherite Axe Max
        inv.add(createItem((byte) 2, "minecraft:netherite_axe", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:sharpness", 5,
            "minecraft:fortune", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7c\u2726 Chi\u1ebfn R\u00ecu B\u1ed5 C\u1ee7i T\u1ed1i Th\u01b0\u1ee3ng VIP \u2726"));

        // Slot 3: Heavy Mace Max (Chùy Thần Thoại 1.21+)
        inv.add(createItem((byte) 3, "minecraft:mace", 1, Map.of(
            "minecraft:density", 5,
            "minecraft:breach", 4,
            "minecraft:wind_burst", 3,
            "minecraft:fire_aspect", 2,
            "minecraft:smite", 5,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7d\u2726 L\u00f4i Th\u1ea7n Ch\u00f9y Mace VIP \u2726"));

        // Slot 4: Bow Max
        inv.add(createItem((byte) 4, "minecraft:bow", 1, Map.of(
            "minecraft:power", 5,
            "minecraft:flame", 1,
            "minecraft:infinity", 1,
            "minecraft:punch", 2,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7e\u2726 Th\u1ea7n Cung H\u1ecfa Di\u1ec7m B\u1ea5t T\u1eadn VIP \u2726"));

        // Slot 5: Trident Max (Loyalty & Channeling)
        inv.add(createItem((byte) 5, "minecraft:trident", 1, Map.of(
            "minecraft:loyalty", 3,
            "minecraft:channeling", 1,
            "minecraft:impaling", 5,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a73\u2726 H\u1ea3i V\u01b0\u01a1ng \u0110inh Ba S\u1ea5m S\u00e9t VIP \u2726"));

        // Slot 6: Crossbow Max
        inv.add(createItem((byte) 6, "minecraft:crossbow", 1, Map.of(
            "minecraft:quick_charge", 3,
            "minecraft:multishot", 1,
            "minecraft:piercing", 4,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a79\u2726 N\u1ecf Th\u1ea7n B\u1eafn T\u1ec9a VIP \u2726"));

        // Slot 7: Táo vàng enchanted x64
        inv.add(createItem((byte) 7, "minecraft:enchanted_golden_apple", 64, null, "\u00a76T\u00e1o V\u00e0ng Ph\u00f9 Ph\u00e9p B\u1ea5t T\u1eed"));

        // Slot 8: Totem Bất tử x64
        inv.add(createItem((byte) 8, "minecraft:totem_of_undying", 64, null, "\u00a7eTotem B\u1ea5t T\u1eed VIP"));

        // --- Armor Slots (100 - 103) ---
        // Boots
        inv.add(createItem((byte) 100, "minecraft:netherite_boots", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:feather_falling", 4,
            "minecraft:depth_strider", 3,
            "minecraft:soul_speed", 3,
            "minecraft:thorns", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a75\u2726 Gi\u00e0y Netherite Vua T\u1ed1c \u0110\u1ed9 VIP \u2726"));

        // Leggings
        inv.add(createItem((byte) 101, "minecraft:netherite_leggings", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:swift_sneak", 3,
            "minecraft:thorns", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a75\u2726 Qu\u1ea7n Netherite B\u1ea5t Ho\u1ea1i VIP \u2726"));

        // Chestplate
        inv.add(createItem((byte) 102, "minecraft:netherite_chestplate", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:thorns", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a75\u2726 \u00c1o Gi\u00e1p Netherite Gai Th\u1ea7n VIP \u2726"));

        // Helmet (Mặt Nạ Hóa Thân Disguise Mask VIP)
        inv.add(createItem((byte) 103, "minecraft:netherite_helmet", 1, Map.of(
            "minecraft:protection", 4,
            "minecraft:respiration", 3,
            "minecraft:aqua_affinity", 1,
            "minecraft:thorns", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a76\u2726 M\u1eb7t N\u1ea1 H\u00f3a Th\u00e2n Netherite VIP \u2726"));

        // --- Offhand Slot (-106) ---
        inv.add(createItem((byte) -106, "minecraft:totem_of_undying", 64, null, "\u00a7eTotem B\u1ea5t T\u1eed VIP"));

        // --- Main Inventory (Slots 9 - 35: FULL 27 SLOTS) ---
        // Slot 9: Elytra Max
        inv.add(createItem((byte) 9, "minecraft:elytra", 1, Map.of(
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7b\u2726 \u0110\u00f4i C\u00e1nh Elytra V\u0129nh C\u1eedu VIP \u2726"));

        // Slot 10: Pháo hoa bay x64
        inv.add(createItem((byte) 10, "minecraft:firework_rocket", 64, null, "\u00a7fPh\u00e1o Hoa Bay Cao C\u1ea5p x64"));

        // Slot 11: Trident Riptide (Bay lượn dưới mưa)
        inv.add(createItem((byte) 11, "minecraft:trident", 1, Map.of(
            "minecraft:riptide", 3,
            "minecraft:impaling", 5,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7b\u2726 H\u1ea3i V\u01b0\u01a1ng Phi Thi\u00ean Trident VIP \u2726"));

        // Slot 12: Netherite Pickaxe Silk Touch Max
        inv.add(createItem((byte) 12, "minecraft:netherite_pickaxe", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:silk_touch", 1,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7a\u2726 Th\u1ea7n C\u00fap Silk Touch VIP \u2726"));

        // Slot 13: Netherite Shovel Max
        inv.add(createItem((byte) 13, "minecraft:netherite_shovel", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:fortune", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7a\u2726 Si\u00eau X\u1ebbng \u0110\u00e0o \u0110\u1ea5t VIP \u2726"));

        // Slot 14: Netherite Hoe Max
        inv.add(createItem((byte) 14, "minecraft:netherite_hoe", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:fortune", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a72\u2726 Th\u1ea7n Cu\u1ed1c L\u00e0m N\u00f4ng VIP \u2726"));

        // Slot 15: Cần câu Max
        inv.add(createItem((byte) 15, "minecraft:fishing_rod", 1, Map.of(
            "minecraft:luck_of_the_sea", 3,
            "minecraft:lure", 3,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a73\u2726 C\u1ea7n C\u00e2u Th\u1ea7n \u0110o\u1ea1t B\u1ea3o VIP \u2726"));

        // Slot 16: Khiên Shield Max
        inv.add(createItem((byte) 16, "minecraft:shield", 1, Map.of(
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a76\u2726 Khi\u00ean Kim Cang H\u1ed9 Th\u1ec3 VIP \u2726"));

        // Slot 17: Kéo Shears Max
        inv.add(createItem((byte) 17, "minecraft:shears", 1, Map.of(
            "minecraft:efficiency", 5,
            "minecraft:silk_touch", 1,
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7f\u2726 K\u00e9o C\u1eaft T\u1ec9a Th\u1ea7n T\u1ed1c VIP \u2726"));

        // Slot 18: Bật lửa Max
        inv.add(createItem((byte) 18, "minecraft:flint_and_steel", 1, Map.of(
            "minecraft:unbreaking", 3,
            "minecraft:mending", 1
        ), "\u00a7c\u2726 B\u1eadt L\u1eeda H\u1ecfa Th\u1ea7n VIP \u2726"));

        // Slot 19: Bóng gió Wind Charge x64
        inv.add(createItem((byte) 19, "minecraft:wind_charge", 64, null, "\u00a7bB\u00f3ng Gi\u00f3 Phong Th\u1ea7n x64"));

        // Slot 20: Ngọc Ender x16
        inv.add(createItem((byte) 20, "minecraft:ender_pearl", 16, null, "\u00a73Ng\u1ecdc Ender T\u1ee9c Th\u1eddi"));

        // Slot 21: Cà rốt vàng x64
        inv.add(createItem((byte) 21, "minecraft:golden_carrot", 64, null, "\u00a76C\u00e0 R\u1ed1t V\u00e0ng H\u1ed3i Ph\u1ee5c x64"));

        // Slot 22: Chai kinh nghiệm x64
        inv.add(createItem((byte) 22, "minecraft:experience_bottle", 64, null, "\u00a7aChai Kinh Nghi\u1ec7m V\u00f4 T\u1eadn x64"));

        // Slot 23: Totem dự phòng x64
        inv.add(createItem((byte) 23, "minecraft:totem_of_undying", 64, null, "\u00a7eTotem B\u1ea5t T\u1eed D\u1ef1 Ph\u00f2ng x64"));

        // Slot 24: Khối Netherite x64
        inv.add(createItem((byte) 24, "minecraft:netherite_block", 64, null, "\u00a78Kh\u1ed1i Netherite Nguy\u00ean Ch\u1ea5t x64"));

        // Slot 25: Khối Kim Cương x64
        inv.add(createItem((byte) 25, "minecraft:diamond_block", 64, null, "\u00a7bKh\u1ed1i Kim C\u01b0\u01a1ng S\u00e1ng L\u00f3a x64"));

        // Slot 26: Khối Ngọc Lục Bảo x64
        inv.add(createItem((byte) 26, "minecraft:emerald_block", 64, null, "\u00a7aKh\u1ed1i Ng\u1ecdc L\u1ee5c B\u1ea3o Giao Th\u01b0\u01a1ng x64"));

        // Slot 27: Khối Vàng x64
        inv.add(createItem((byte) 27, "minecraft:gold_block", 64, null, "\u00a7eKh\u1ed1i V\u00e0ng Ho\u00e0ng Gia x64"));

        // Slot 28: Đèn hiệu Beacon x64
        inv.add(createItem((byte) 28, "minecraft:beacon", 64, null, "\u00a7b\u0110\u00e8n Hi\u1ec7u H\u1ea3i \u0110\u0103ng Beacon x64"));

        // Slot 29: Sao Nether x64
        inv.add(createItem((byte) 29, "minecraft:nether_star", 64, null, "\u00a7fSao Nether Th\u1ea7n Th\u00e1nh x64"));

        // Slot 30: Lõi nặng Heavy Core x16
        inv.add(createItem((byte) 30, "minecraft:heavy_core", 16, null, "\u00a7dHeavy Core \u0110\u00fac Ch\u00f9y Mace x16"));

        // Slot 31: Trứng rồng Dragon Egg x1
        inv.add(createItem((byte) 31, "minecraft:dragon_egg", 1, null, "\u00a75Tr\u1ee9ng R\u1ed3ng Huy\u1ec1n Tho\u1ea1i"));

        // Slot 32: Hộp Shulker x64
        inv.add(createItem((byte) 32, "minecraft:shulker_box", 64, null, "\u00a7dKho Ch\u1ee9a \u0110\u1ed3 H\u1ed9p Shulker x64"));

        // Slot 33: Rương Ender x64
        inv.add(createItem((byte) 33, "minecraft:ender_chest", 64, null, "\u00a73R\u01b0\u01a1ng Ender Kh\u00f4ng Gian x64"));

        // Slot 34: Máy chế tạo Crafter x64
        inv.add(createItem((byte) 34, "minecraft:crafter", 64, null, "\u00a76M\u00e1y Ch\u1ebf T\u1ea1o T\u1ef1 \u0110\u1ed9ng Crafter x64"));

        // Slot 35: Mũi tên x64
        inv.add(createItem((byte) 35, "minecraft:arrow", 64, null, "\u00a7fM\u0169i T\u00ean B\u1eafn Cung x64"));

        playerTag.put("Inventory", inv);

        // ==========================================
        // 2. ENDER CHEST INVENTORY (27 SLOTS FULL)
        // ==========================================
        ListTag enderInv = new ListTag();

        // 0-3: Thỏi Netherite, Kim cương, Phôi vàng, Ngọc lục bảo
        enderInv.add(createItem((byte) 0, "minecraft:netherite_ingot", 64, null, "\u00a78Th\u1ecfi Netherite x64"));
        enderInv.add(createItem((byte) 1, "minecraft:diamond", 64, null, "\u00a7bKim C\u01b0\u01a1ng x64"));
        enderInv.add(createItem((byte) 2, "minecraft:ancient_debris", 64, null, "\u00a74M\u1ea3nh V\u1ee5n C\u1ed5 \u0110\u1ea1i x64"));
        enderInv.add(createItem((byte) 3, "minecraft:gold_ingot", 64, null, "\u00a7eTh\u1ecfi V\u00e0ng x64"));

        // 4-7: Vật phẩm 1.21 mới (Breeze rod, Trial key, Ominous trial key, Wind charge)
        enderInv.add(createItem((byte) 4, "minecraft:breeze_rod", 64, null, "\u00a7bBreeze Rod x64"));
        enderInv.add(createItem((byte) 5, "minecraft:trial_key", 64, null, "\u00a76Ch\u00eca Kh\u00f3a H\u1ea7m Ng\u1ee5c Trial Key x64"));
        enderInv.add(createItem((byte) 6, "minecraft:ominous_trial_key", 64, null, "\u00a75Ch\u00eca Kh\u00f3a H\u1eafc \u00c1m Ominous Key x64"));
        enderInv.add(createItem((byte) 7, "minecraft:ominous_bottle", 64, null, "\u00a75B\u00ecnh \u0110i\u1ec1m X\u1ea5u Ominous Bottle V x64"));

        // 8-11: Khối kiến trúc và tiện ích
        enderInv.add(createItem((byte) 8, "minecraft:anvil", 64, null, "\u00a77\u0110e R\u00e8n S\u1eaft x64"));
        enderInv.add(createItem((byte) 9, "minecraft:enchanting_table", 64, null, "\u00a7dB\u00e0n Ph\u00f9 Ph\u00e9p x64"));
        enderInv.add(createItem((byte) 10, "minecraft:bookshelf", 64, null, "\u00a76K\u1ec7 S\u00e1ch Ph\u00f9 Ph\u00e9p x64"));
        enderInv.add(createItem((byte) 11, "minecraft:brewing_stand", 64, null, "\u00a7cGi\u00e0n Pha Thu\u1ed1c x64"));

        // 12-15: Shulker Box các màu đầy đủ
        enderInv.add(createItem((byte) 12, "minecraft:black_shulker_box", 16, null, "\u00a78H\u1ed9p Shulker \u0110en x16"));
        enderInv.add(createItem((byte) 13, "minecraft:white_shulker_box", 16, null, "\u00a7fH\u1ed9p Shulker Tr\u1eafng x16"));
        enderInv.add(createItem((byte) 14, "minecraft:purple_shulker_box", 16, null, "\u00a75H\u1ed9p Shulker T\u00edm x16"));
        enderInv.add(createItem((byte) 15, "minecraft:cyan_shulker_box", 16, null, "\u00a73H\u1ed9p Shulker L\u1ee5c Lam x16"));

        // 16-19: Totem và Táo vàng dự trữ chiến tranh
        enderInv.add(createItem((byte) 16, "minecraft:enchanted_golden_apple", 64, null, "\u00a76T\u00e1o V\u00e0ng Ph\u00f9 Ph\u00e9p B\u1ea5t T\u1eed x64"));
        enderInv.add(createItem((byte) 17, "minecraft:totem_of_undying", 64, null, "\u00a7eTotem B\u1ea5t T\u1eed Kho D\u1ef1 Tr\u1eef x64"));
        enderInv.add(createItem((byte) 18, "minecraft:totem_of_undying", 64, null, "\u00a7eTotem B\u1ea5t T\u1eed Kho D\u1ef1 Tr\u1eef x64"));
        enderInv.add(createItem((byte) 19, "minecraft:firework_rocket", 64, null, "\u00a7fPh\u00e1o Hoa Bay D\u1ef1 Tr\u1eef x64"));

        // 20-23: Vật phẩm hiếm khác
        enderInv.add(createItem((byte) 20, "minecraft:nether_star", 64, null, "\u00a7fSao Nether Th\u1ea7n Th\u00e1nh x64"));
        enderInv.add(createItem((byte) 21, "minecraft:beacon", 64, null, "\u00a7b\u0110\u00e8n Hi\u1ec7u Beacon x64"));
        enderInv.add(createItem((byte) 22, "minecraft:heavy_core", 16, null, "\u00a7dHeavy Core x16"));
        enderInv.add(createItem((byte) 23, "minecraft:dragon_head", 16, null, "\u00a75\u0110\u1ea7u R\u1ed3ng Ender x16"));

        // 24-26: Phù chú và tài nguyên đỏ
        enderInv.add(createItem((byte) 24, "minecraft:redstone_block", 64, null, "\u00a7cKh\u1ed1i \u0110\u00e1 \u0110\u1ecf x64"));
        enderInv.add(createItem((byte) 25, "minecraft:lapis_block", 64, null, "\u00a79Kh\u1ed1i Ng\u1ecdc L\u01b0u Ly x64"));
        enderInv.add(createItem((byte) 26, "minecraft:obsidian", 64, null, "\u00a78H\u1eafc Di\u1ec7u Th\u1ea1ch Obsidian x64"));

        playerTag.put("EnderItems", enderInv);

        // Lưu file
        NbtIo.writeCompressed(playerTag, playerFile.toPath());
        System.out.println("=== THANH CONG! ===");
        System.out.println("1. Da phu ma MAX TOAN BO vu khi, giap, cong cu (Netherite Sword, Mace, Pickaxes, Axe, Shovel, Hoe, Bow, Crossbow, Tridents, Shield, Shears, Fishing Rod, Flint&Steel, Elytra, Full Netherite Armor).");
        System.out.println("2. Da them day du tat ca 36 o tui do va them FULL 27 o trong Ruong Ender (Ender Chest) voi vo so kho bau & vat pham cuc hiem 1.21.");
        System.out.println("3. Level nhan vat da duoc set len 99 (XpTotal 14194).");
    }
}

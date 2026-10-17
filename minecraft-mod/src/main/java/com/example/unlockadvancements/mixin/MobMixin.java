package com.example.unlockadvancements.mixin;

import com.example.unlockadvancements.MorphManager;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Mob;
import net.minecraft.world.entity.player.Player;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(Mob.class)
public abstract class MobMixin {

    @Inject(method = "asValidTarget", at = @At("HEAD"), cancellable = true)
    private void onAsValidTarget(LivingEntity target, CallbackInfoReturnable<LivingEntity> cir) {
        if (target instanceof Player player) {
            Mob mob = (Mob) (Object) this;
            if (MorphManager.shouldMobIgnore(mob, player)) {
                cir.setReturnValue(null);
            }
        }
    }

    @Inject(method = "canAttack", at = @At("HEAD"), cancellable = true)
    private void onCanAttack(LivingEntity target, CallbackInfoReturnable<Boolean> cir) {
        if (target instanceof Player player) {
            Mob mob = (Mob) (Object) this;
            if (MorphManager.shouldMobIgnore(mob, player)) {
                cir.setReturnValue(false);
            }
        }
    }

    @Inject(method = "aiStep", at = @At("HEAD"))
    private void onAiStep(CallbackInfo ci) {
        Mob mob = (Mob) (Object) this;
        MorphManager.tickMobSuspicion(mob);
    }
}

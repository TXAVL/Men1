package com.example.unlockadvancements.mixin;

import com.example.unlockadvancements.MorphManager;
import com.example.unlockadvancements.UnlockAdvancementsMod;
import net.minecraft.client.renderer.entity.EntityRenderDispatcher;
import net.minecraft.client.renderer.entity.EntityRenderer;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.player.Player;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(EntityRenderDispatcher.class)
public abstract class EntityRenderDispatcherMixin {
    @Shadow
    public abstract <T extends Entity> EntityRenderer<? super T, ?> getRenderer(T entity);

    @Inject(method = "extractEntity", at = @At("HEAD"), cancellable = true)
    @SuppressWarnings({"rawtypes", "unchecked"})
    public <E extends Entity> void onExtractEntity(E entity, float tickDelta, CallbackInfoReturnable<EntityRenderState> cir) {
        // Only replace the state for the world entity pass; other callers cast the result to AvatarRenderState
        if (!MorphManager.isExtractingWorldEntities) {
            return;
        }
        if (!(entity instanceof Player player) || !MorphManager.isMorphed(player)) {
            return;
        }

        LivingEntity dummy = MorphManager.getClientDummy(player);
        if (dummy == null) {
            return;
        }
        try {
            MorphManager.syncDummyWithPlayer(dummy, player);
            EntityRenderer renderer = this.getRenderer(dummy);
            if (renderer != null) {
                EntityRenderState state = renderer.createRenderState(dummy, tickDelta);
                if (state != null) {
                    cir.setReturnValue(state);
                }
            }
        } catch (Throwable t) {
            // Never crash the render loop: fall back to the normal player model for this mob type
            UnlockAdvancementsMod.LOGGER.warn("Khong the render hinh dang hoa than " + dummy.getType() + ", dung lai model nguoi choi", t);
            MorphManager.markRenderFailed(player, dummy.getType());
        }
    }
}

/*
 * Copyright (c) 2014, STMicroelectronics International N.V.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <asm.S>
#include <arm.h>
#include <arm32_macros.S>
#include <sm/teesmc.h>
#include <sm/teesmc_opteed_macros.h>
#include <sm/teesmc_opteed.h>
#include <kernel/thread_defs.h>

	.section .text.thread_asm

LOCAL_FUNC vector_std_smc_entry , :
	push	{r0-r7}
	mov	r0, sp
	bl	thread_handle_std_smc
	/*
	 * Normally thread_handle_std_smc() should return via
	 * thread_exit(), thread_rpc(), but if thread_handle_std_smc()
	 * hasn't switched stack (error detected) it will do a normal "C"
	 * return.
	 */
	pop	{r1-r8}
	ldr	r0, =TEESMC_OPTEED_RETURN_CALL_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_std_smc_entry

LOCAL_FUNC vector_fast_smc_entry , :
	push	{r0-r7}
	mov	r0, sp
	bl	thread_handle_fast_smc
	pop	{r1-r8}
	ldr	r0, =TEESMC_OPTEED_RETURN_CALL_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_fast_smc_entry

LOCAL_FUNC vector_fiq_entry , :
 	/* Secure Monitor received a FIQ and passed control to us. */
	bl	thread_check_canaries
 	ldr	lr, =thread_fiq_handler_ptr
 	ldr	lr, [lr]
 	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_FIQ_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_fiq_entry

LOCAL_FUNC vector_cpu_on_entry , :
	ldr	lr, =thread_cpu_on_handler_ptr
	ldr	lr, [lr]
	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_ON_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_cpu_on_entry

LOCAL_FUNC vector_cpu_off_entry , :
	ldr	lr, =thread_cpu_off_handler_ptr
	ldr	lr, [lr]
	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_OFF_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_cpu_off_entry

LOCAL_FUNC vector_cpu_suspend_entry , :
	ldr	lr, =thread_cpu_suspend_handler_ptr
	ldr	lr, [lr]
	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_SUSPEND_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_cpu_suspend_entry

LOCAL_FUNC vector_cpu_resume_entry , :
	ldr	lr, =thread_cpu_resume_handler_ptr
	ldr	lr, [lr]
	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_RESUME_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_cpu_resume_entry

LOCAL_FUNC vector_system_off_entry , :
	ldr	lr, =thread_system_off_handler_ptr
	ldr	lr, [lr]
	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_SYSTEM_OFF_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_system_off_entry

LOCAL_FUNC vector_system_reset_entry , :
	ldr	lr, =thread_system_reset_handler_ptr
	ldr	lr, [lr]
	blx	lr
	mov	r1, r0
	ldr	r0, =TEESMC_OPTEED_RETURN_SYSTEM_RESET_DONE
	smc	#0
	b	.	/* SMC should not return */
END_FUNC vector_system_reset_entry

/*
 * Vector table supplied to ARM Trusted Firmware (ARM-TF) at
 * initialization.  Also used when compiled with the internal monitor, but
 * the cpu_*_entry and system_*_entry are not used then.
 *
 * Note that ARM-TF depends on the layout of this vector table, any change
 * in layout has to be synced with ARM-TF. This layout must also be kept in
 * sync with sm_entry_vector in sm.c
 */
FUNC thread_vector_table , :
	b	vector_std_smc_entry
	b	vector_fast_smc_entry
	b	vector_cpu_on_entry
	b	vector_cpu_off_entry
	b	vector_cpu_resume_entry
	b	vector_cpu_suspend_entry
	b	vector_fiq_entry
	b	vector_system_off_entry
	b	vector_system_reset_entry
END_FUNC thread_vector_table

FUNC thread_set_abt_sp , :
	mrs	r1, cpsr
	cps	#CPSR_MODE_ABT
	mov	sp, r0
	msr	cpsr, r1
	bx	lr
END_FUNC thread_set_abt_sp

FUNC thread_set_irq_sp , :
	mrs	r1, cpsr
	cps	#CPSR_MODE_IRQ
	mov	sp, r0
	msr	cpsr, r1
	bx	lr
END_FUNC thread_set_irq_sp

FUNC thread_set_fiq_sp , :
	mrs	r1, cpsr
	cps	#CPSR_MODE_FIQ
	mov	sp, r0
	msr	cpsr, r1
	bx	lr
END_FUNC thread_set_fiq_sp

/* void thread_resume(struct thread_ctx_regs *regs) */
FUNC thread_resume , :
	add	r12, r0, #(13 * 4)	/* Restore registers r0-r12 later */

	cps	#CPSR_MODE_SYS
	ldm	r12!, {sp, lr}

	cps	#CPSR_MODE_SVC
	ldm	r12!, {r1, sp, lr}
	msr	spsr_fsxc, r1

	cps	#CPSR_MODE_SVC
	ldm	r12, {r1, r2}
	push	{r1, r2}

	ldm	r0, {r0-r12}


	/* Restore CPSR and jump to the instruction to resume at */
	rfefd	sp!
END_FUNC thread_resume

/*
 * Disables IRQ and FIQ and saves state of thread, returns original
 * CPSR.
 */
LOCAL_FUNC thread_save_state , :
	push	{r12, lr}
	/*
	 * Uses stack for temporary storage, while storing needed
	 * context in the thread context struct.
	 */

	mrs	r12, cpsr

	cpsid	aif			/* Disable Async abort, IRQ and FIQ */

	push	{r4-r7}
	push	{r0-r3}

	mov	r5, r12			/* Save CPSR in a preserved register */
	mrs	r6, cpsr		/* Save current CPSR */

	bl	thread_get_ctx_regs

	pop	{r1-r4}			/* r0-r3 pushed above */
	stm	r0!, {r1-r4}
	pop	{r1-r4}			/* r4-r7 pushed above */
	stm	r0!, {r1-r4}
	stm	r0!, {r8-r11}

	pop	{r12, lr}
	stm	r0!, {r12}

        cps     #CPSR_MODE_SYS
        stm     r0!, {sp, lr}

        cps     #CPSR_MODE_SVC
        mrs     r1, spsr
        stm     r0!, {r1, sp, lr}

	msr	cpsr, r6		/* Restore mode */

	mov	r0, r5			/* Return original CPSR */
	bx	lr
END_FUNC thread_save_state

FUNC thread_std_smc_entry , :
	/* Pass r0-r7 in a struct thread_smc_args */
	push	{r0-r7}
	mov	r0, sp
	ldr	lr, =thread_std_smc_handler_ptr
	ldr	lr, [lr]
	blx	lr
	/*
	 * Load the returned r0-r3 into preserved registers and skip the
	 * "returned" r4-r7 since they will not be returned to normal
	 * world.
	 */
	pop	{r4-r7}
	add	sp, #(4 * 4)

	/* Disable interrupts before switching to temporary stack */
	cpsid	if
	bl	thread_get_tmp_sp
	mov	sp, r0

	bl	thread_state_free

	ldr	r0, =TEESMC_OPTEED_RETURN_CALL_DONE
	mov	r1, r4
	mov	r2, r5
	mov	r3, r6
	mov	r4, r7
	smc	#0
	b	.	/* SMC should not return */
END_FUNC thread_std_smc_entry


/* void thread_rpc(uint32_t rv[THREAD_RPC_NUM_ARGS]) */
FUNC thread_rpc , :
	push	{lr}
	push	{r0}

	bl	thread_save_state
	mov	r4, r0			/* Save original CPSR */

	/*
 	 * Switch to temporary stack and SVC mode. Save CPSR to resume into.
	 */
	bl	thread_get_tmp_sp
	ldr	r5, [sp]		/* Get pointer to rv[] */
	cps	#CPSR_MODE_SVC		/* Change to SVC mode */
	mov	sp, r0			/* Switch to tmp stack */

	mov	r0, #THREAD_FLAGS_COPY_ARGS_ON_RETURN
	mov	r1, r4			/* CPSR to restore */
	ldr	r2, =.thread_rpc_return
	bl	thread_state_suspend
	mov	r4, r0			/* Supply thread index */
	ldr	r0, =TEESMC_OPTEED_RETURN_CALL_DONE
	ldm	r5, {r1-r3}		/* Load rv[] into r0-r2 */
	smc	#0
	b	.	/* SMC should not return */

.thread_rpc_return:
	/*
	 * At this point has the stack pointer been restored to the value
	 * it had when thread_save_state() was called above.
	 *
	 * Jumps here from thread_resume above when RPC has returned. The
	 * IRQ and FIQ bits are restored to what they where when this
	 * function was originally entered.
	 */
	pop	{r12}			/* Get pointer to rv[] */
	stm	r12, {r0-r2}		/* Store r0-r2 into rv[] */
	pop	{pc}
END_FUNC thread_rpc

LOCAL_FUNC thread_fiq_handler , :
	/* FIQ has a +4 offset for lr compared to preferred return address */
	sub     lr, lr, #4
	push	{r0-r12, lr}
	bl	thread_check_canaries
	ldr	lr, =thread_fiq_handler_ptr
	ldr	lr, [lr]
	blx	lr
	pop	{r0-r12, lr}
	movs	pc, lr
END_FUNC thread_fiq_handler

LOCAL_FUNC thread_irq_handler , :
	/*
	 * IRQ mode is set up to use tmp stack so FIQ has to be
	 * disabled before touching the stack. We can also assign
	 * SVC sp from IRQ sp to get SVC mode into the state we
	 * need when doing the SMC below.
	 */
	cpsid	f			/* Disable FIQ also */
	sub	lr, lr, #4
	push	{lr}
	push	{r12}

	bl	thread_save_state

	mov	r0, #THREAD_FLAGS_EXIT_ON_IRQ
	mrs	r1, spsr
	pop	{r12}
	pop	{r2}
	blx	thread_state_suspend
	mov	r4, r0		/* Supply thread index */

	/*
	 * Switch to SVC mode and copy current stack pointer as it already
	 * is the tmp stack.
	 */
	mov	r0, sp
	cps	#CPSR_MODE_SVC
	mov	sp, r0

	ldr	r0, =TEESMC_OPTEED_RETURN_CALL_DONE
	ldr	r1, =TEESMC_RETURN_RPC_IRQ
	mov	r2, #0
	mov	r3, #0
	/* r4 is already filled in above */
	smc	#0
	b	.	/* SMC should not return */
END_FUNC thread_irq_handler

FUNC thread_init_vbar , :
	/* Set vector (VBAR) */
	ldr	r0, =thread_vect_table
	write_vbar r0
	bx	lr
END_FUNC thread_init_vbar

/*
 * Below are low level routines handling entry and return from user mode.
 *
 * thread_enter_user_mode() saves all that registers user mode can change
 * so kernel mode can restore needed registers when resuming execution
 * after the call to thread_enter_user_mode() has returned.
 * thread_enter_user_mode() doesn't return directly since it enters user
 * mode instead, it's thread_unwind_user_mode() that does the
 * returning by restoring the registers saved by thread_enter_user_mode().
 *
 * There's three ways for thread_enter_user_mode() to return to caller,
 * user TA calls utee_return, user TA calls utee_panic or through an abort.
 *
 * Calls to utee_return or utee_panic are handled as:
 * thread_svc_handler() -> tee_svc_handler() ->	tee_svc_do_call() which
 * calls tee_svc_sys_return() or tee_svc_sys_panic().
 *
 * These function calls returns normally except thread_svc_handler() which
 * which is an exception handling routine so it reads return address and
 * SPSR to restore from the stack. tee_svc_sys_return() and tee_svc_sys_panic()
 * changes return address and SPSR used by thread_svc_handler() to instead of
 * returning into user mode as with other syscalls it returns into
 * thread_unwind_user_mode() in kernel mode instead.  When
 * thread_svc_handler() returns the stack pointer at the point where
 * thread_enter_user_mode() left it so this is where
 * thread_unwind_user_mode() can operate.
 *
 * Aborts are handled in a similar way but by thread_abort_handler()
 * instead, when the pager sees that it's an abort from user mode that
 * can't be handled it updates SPSR and return address used by
 * thread_abort_handler() to return into thread_unwind_user_mode()
 * instead.
 */

/*
 * TEE_Result thread_enter_user_mode(
 *              uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3,
 *              tee_uaddr_t sp, tee_uaddr_t user_func,
 *              uint32_t *panicked, uint32_t *panic_code);
 * See description in thread.h
 */
FUNC thread_enter_user_mode , :
	/*
	 * Save all registers to allow tee_svc_sys_return() to
	 * resume execution as if this function would have returned.
	 * This is also used in tee_svc_sys_panic().
	 *
	 * If stack usage of this function is changed
	 * thread_unwind_user_mode() has to be updated.
	 */
	push    {r4-r12,lr}

	ldr     r4, [sp, #(10 * 0x4)]   /* user stack pointer */
	ldr     r5, [sp, #(11 * 0x4)]   /* user function */

	/*
	 * Save old user sp and set new user sp.
	 */
	cps	#CPSR_MODE_SYS
	mov	r6, sp
	mov     sp, r4
	cps	#CPSR_MODE_SVC
	push	{r6}

	/*
	 * Set the saved Processors Status Register to user mode to allow
	 * entry of user mode through movs below. Also update thumbstate
	 * since movs doesn't do that automatically.
	 */
	mrs     r6, cpsr
	bic     r6, #CPSR_MODE_MASK
	orr	r6, #CPSR_MODE_USR
	tst     r5, #1	/* If it's odd we should switch to thumb mode */
	orrne   r6, #CPSR_T		/* Enable thumb mode */
	biceq   r6, #CPSR_T		/* Disable thumb mode */
	bicne   r6, #CPSR_IT_MASK1	/* Clear IT state for thumb mode */
	bicne   r6, #CPSR_IT_MASK2	/* Clear IT state for thumb mode */
	msr     spsr_cxsf, r6

	/*
	* Don't allow return from this function, return is done through
	* thread_unwind_user_mode() below.
	*/
	mov     lr, #0
	/* Call the user function with its arguments */
	movs    pc, r5
END_FUNC thread_enter_user_mode

/*
 * void thread_unwind_user_mode(uint32_t ret, uint32_t exit_status0,
 *              uint32_t exit_status1);
 * See description in thread.h
 */
FUNC thread_unwind_user_mode , :
	ldr     ip, [sp, #(13 * 0x4)]   /* &ctx->panicked */
	str	r1, [ip]
	ldr     ip, [sp, #(14 * 0x4)]   /* &ctx->panic_code */
	str	r2, [ip]

	/* Restore old user sp */
	pop	{r4}
	cps	#CPSR_MODE_SYS
	mov	sp, r4
	cps	#CPSR_MODE_SVC

	pop     {r4-r12,pc}	/* Match the push in thread_enter_user_mode()*/
END_FUNC thread_unwind_user_mode

LOCAL_FUNC thread_abort_handler , :
thread_abort_handler:
thread_und_handler:
	/*
	 * Switch to abort mode to use that stack instead.
	 */
	cps	#CPSR_MODE_ABT
	push	{r0-r11, ip}
	cps	#CPSR_MODE_UND
	sub	r1, lr, #4
	mrs	r0, spsr
	cps	#CPSR_MODE_ABT
	push	{r0, r1}
	msr	spsr_fsxc, r0	/* In case some code reads spsr directly */
	mov	r0, #THREAD_ABORT_UNDEF
	b	.thread_abort_generic

thread_dabort_handler:
	push	{r0-r11, ip}
	sub	r1, lr, #8
	mrs	r0, spsr
	push	{r0, r1}
	mov	r0, #THREAD_ABORT_DATA
	b	.thread_abort_generic

thread_pabort_handler:
	push	{r0-r11, ip}
	sub	r1, lr, #4
	mrs	r0, spsr
	push	{r0, r1}
	mov	r0, #THREAD_ABORT_PREFETCH
	b	.thread_abort_generic

.thread_abort_generic:
	cps	#CPSR_MODE_SYS
	mov	r1, sp
	mov	r2, lr
	cps	#CPSR_MODE_ABT
	push	{r1-r3}
	mov	r1, sp
	bl	thread_handle_abort
	pop	{r1-r3}
	cps	#CPSR_MODE_SYS
	mov	sp, r1
	mov	lr, r2
	cps	#CPSR_MODE_ABT
	pop	{r0, r1}
	mov	lr, r1
	msr	spsr_fsxc, r0
	pop	{r0-r11, ip}
	movs	pc, lr
END_FUNC thread_abort_handler

LOCAL_FUNC thread_svc_handler , :
	push	{r0-r7, lr}
	mrs	r0, spsr
	push	{r0}
	mov	r0, sp
	ldr	lr, =thread_svc_handler_ptr;
	ldr	lr, [lr]
	blx	lr
	pop	{r0}
	msr	spsr_fsxc, r0
	pop	{r0-r7, lr}
	movs	pc, lr
END_FUNC thread_svc_handler

        .align	5
LOCAL_FUNC thread_vect_table , :
	b	.			/* Reset			*/
	b	thread_und_handler	/* Undefined instruction	*/
	b	thread_svc_handler	/* System call			*/
	b	thread_pabort_handler	/* Prefetch abort		*/
	b	thread_dabort_handler	/* Data abort			*/
	b	.			/* Reserved			*/
	b	thread_irq_handler	/* IRQ				*/
	b	thread_fiq_handler	/* FIQ				*/
END_FUNC thread_vect_table
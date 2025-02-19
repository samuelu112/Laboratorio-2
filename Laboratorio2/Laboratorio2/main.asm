; UNIVERSIDAD DEL VALLE DE GUATEMALA
; IE2023: Programación de microcontroladores
; Laboratorio 2.asm
;
; Autor : Eduardo Samuel Urbina Pérez
; Proyecto : laboratorio 2
; Hardware : ATmega 328
; Creado: 12/02/2025
; Descripción: el laboratorio 2 consiste en hacer un contador de 4 bits y que incremente cada 100ms 
;junto con un contador con 2 botones mostrado en un diplay de 7 segmentos sin interrumpir el contador de 4 bits

.include "M328PDEF.inc"
.cseg
.org 0x0000

;---------------------------------------------------------
; Configuración de la pila
LDI   R16, LOW(RAMEND)
OUT   SPL, R16
LDI   R16, HIGH(RAMEND)
OUT   SPH, R16

;---------------------------------------------------------
; Configuración del MCU
SETUP:
    ; Configurar Prescaler principal para tener 1MHz
    LDI   R16, (1<<CLKPCE)
    STS   CLKPR, R16       ; Habilitar cambio de prescaler
    LDI   R16, 0b00000100
    STS   CLKPR, R16       ; Configurar prescaler a 16 F_cpu = 1MHz

    ; Inicializar Timer0
    CALL  INIT_TMR0

    ;Configurar PORTB como salida
    LDI   R16, 0xFF
    OUT   DDRB, R16

    ;Valores iniciales variables
    LDI   R24, 0x00 ;Contador de 4 bits
    LDI   R25,   0x00 ;Contador de overflows

	//Configurar puertos
	//PD2 y PD7 - Entrada
	//Configurar puerto C como entrada con pull-ups habilitados
	LDI		R16, 0x00
	OUT		DDRC, R16 //Configurar puerto C como entrada
	LDI		R16, 0xFF
	OUT		PORTC, R16 //Habilitara pull-ups
	//PB y PD - Salida
	//Configurar puerto B y D como salida
	LDI		R16, 0xFF
	OUT		DDRB, R16 //Configurar puerto B como salida
	OUT		DDRD, R16 //Configurar puerto D como salida


	LDI		R19, 0b00111111 ;0
	LDI		ZL, 0x00
	LDI		ZH, 0x01
	ST		Z, R19
	LDI		R19, 0b00000110 ;1
	ST		Z+, R19
	LDI		R19, 0B01011011 ;2
	ST		Z+, R19
	LDI		R19, 0B01001111 ;3
	ST		Z+, R19
	LDI		R19, 0B01100110 ;4
	ST		Z+, R19
	LDI		R19, 0B01101101 ;5
	ST		Z+, R19
	LDI		R19, 0B01111101 ;6
	ST		Z+, R19
	LDI		R19, 0B00000111 ;7
	ST		Z+, R19
	LDI		R19, 0B01111111 ;8
	ST		Z+, R19
	LDI		R19, 0B01100111 ;9
	ST		Z+, R19
	LDI		R19, 0B01110111 ;A
	ST		Z+, R19
	LDI		R19, 0B01111111 ;B
	ST		Z+, R19
	LDI		R19, 0B00111001 ;C
	ST		Z+,	R19
	LDI		R19, 0B00111111 ;D
	ST		Z+, R19
	LDI		R19, 0B01111001 ;E
	ST		Z+, R19
	LDI		R19, 0B01110001 ;F
	ST		Z+, R19

	LDI		ZL, 0xFF
	LDI		ZH, 0x00
	LDI		R18, 0xFF
	LDI		R20, 0X00
;---------------------------------------------------------
;Loop principal
LOOP:
    IN		R16, TIFR0
    SBRS	R16, TOV0 ;Si TOV0 está seteado, salta la siguiente instrucción
    RJMP	LOOP ;Si no, sigue esperando
	CALL	OCLOCK

	IN		R17, PINC //Leer puerto C
	CP		R18, R17 //Se apagó algun bit del puerto C?
	BREQ	LOOP

	MOV		R18, R17 //Se guarda estado nuevo de botones
	SBRC	R17, 0
	CALL	SUMAR
	SBRC	R17, 1
	CALL	RESTAR

	MOV		R20, ZL
	CPI		R20, 0X0F
	BREQ	REINICIO1
	CPI		R20, 0XFE
	BREQ	REINICIO2
	RJMP	LOOP
OCLOCK:
	;Limpiar la bandera de overflow escribiendo 1 en TOV0
    SBI		TIFR0, TOV0

    ;Poner 100 en TCNT0 para que el overflow ocurra en ~10ms
    LDI		R16, 100
    OUT		TCNT0, R16

    ;Incrementar el contador de R25
    INC		R25
    CPI		R25, 10 ;10 overflows = 10 × 10ms = 100ms
    BRNE	ORET ;Si aún no se llega a 10, volver al loop
    ;Se alcanzaron 100ms resetear el contador de R25
    CLR		R25

    ;Incrementar el contador binario de 4 bits
    INC		R24
    ANDI	R24, 0x0F ;Mantenerlo en 4 bits

    ;Mostrar el valor del contador en PORTB
    OUT		PORTB, R24
	CPI		R24, 0X05
	BRNE	OCLOCK
	IN		R17, PINC //Leer puerto C
	CP		R18, R17 //Se apagó algun bit del puerto C?
	BREQ	OCLOCK
	RET

ORET:
	RET
;---------------------------------------------------------
;Subrutina para inicializar Timer0
INIT_TMR0:
    ;Configurar Timer0: prescaler de 64 para generar un overflow en 10ms
    LDI		R16, (1<<CS01) | (1<<CS00)
    OUT		TCCR0B, R16
    LDI		R16, 100
    OUT		TCNT0, R16
    RET
SUMAR:
    LD		R19, Z+
    OUT		PORTD, R19
    RET
RESTAR:
    LD		R19, -Z
    OUT		PORTD, R19
    RET
REINICIO1:
	LDI		ZL, 0XFF
	LDI		ZH,	0X00
	RJMP	LOOP
REINICIO2:
	LDI		ZL, 0X0E
	LDI		ZH, 0X01
	RJMP	LOOP

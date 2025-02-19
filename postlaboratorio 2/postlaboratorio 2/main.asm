; UNIVERSIDAD DEL VALLE DE GUATEMALA
; IE2023: Programación de microcontroladores
; Postlaboratorio 2.asm
;
; Autor : Eduardo Samuel Urbina Pérez
; Proyecto : Postlaboratorio 2
; Hardware : ATmega 328
; Creado: 12/02/2025
; Descripción: el postlaboratorio 2 consiste en hacer un contador de 4 bits y que incremente cada 1s 
;junto con un contador con 2 botones mostrado en un diplay de 7 segmentos, cada vez que tengan el mismo valor
;los dos contadores se va a reiniciar el contador en segundos y se enciende alarma en el pin 2 del PORTC

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

    ;Valores iniciales variables
    LDI   R24, 0x00 ;Contador de 4 bits
    LDI   R25, 0x00 ;Contador de overflows

	//Configurar puertos
	//PC0 y PC1 - Entrada
	//Configurar puerto C como entrada y salida con pull-ups habilitados
	LDI		R16, 0B00000100
	OUT		DDRC, R16 //Configurar puerto C como entrada y salida
	LDI		R16, 0B11111011
	OUT		PORTC, R16 //Habilitara pull-ups
	//PB y PD - Salida
	//Configurar puerto B y D como salida
	LDI		R16, 0xFF
	OUT		DDRB, R16 //Configurar puerto B como salida
	OUT		DDRD, R16 //Configurar puerto D como salida

	;Direccionamiento indirecto de 0x0100 a 0x010F
	LDI		ZL, 0x00
	LDI		ZH, 0x01
	LDI		R19, 0b00111111 ;0
	ST		Z+, R19
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

	;Valores iniciales, indicador en 0x0100
	;Direccion
	LDI		ZL, 0x00
	LDI		ZH, 0x01
	;Memoria pulsadores
	LDI		R18, 0xFF
	;Memoria de direccion
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
	SBRC	R17, 0	//Si se pone en 0 el bit 0 ejecuta restar
	CALL	SUMAR
	SBRC	R17, 1 //Si se pone en 0 el bit 1 ejecuta sumar
	CALL	RESTAR
	;Valor de la direccion indirecta
	MOV		R20, ZL
	CPI		R20, 0x10 //Si está en 16 el display saltar a reinicio 1
	BREQ	REINICIO1
	CPI		R20, 0xFF //Si está en menos de 0 saltar a reinicio 2
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
	//Contador de overflows para 1S
	INC		R27
    CPI		R27, 10 ;10 overflows = 10 × 100ms = 1000ms
    BRNE	ORET ;Si aún no se llega a 10, volver al loop
    ;Se alcanzaron 100ms resetear el contador de R27
    CLR		R27
 
    ;Incrementar el contador binario de 4 bits
    INC		R24
    ANDI	R24, 0x0F ;Mantenerlo en 4 bits
	;Comparacion de direccionamiento indirecto y contador en segundos
	CP		R20, R24 //Son iguales salta a limpiar
	BREQ	LIMPIAR
MOSTRAR: //Regresa Limpiar para mostrar en PORTB
	;Mostrar el valor del contador en PORTB
    OUT		PORTB, R24
	CPI		R27, 0x05	//Antirebote, cada que pasa 500ms
	BRNE	OCLOCK		//Si no pasa regresar
	IN		R17, PINC //Leer puerto C
	CP		R18, R17 //Se apagó algun bit del puerto C?
	BREQ	OCLOCK
	RET
;Ayuda a saltar a Loop si el contador de 1S no llega a 10
ORET:
	RET	
;Reinicia contador de segundos Y togglea el pinc2
LIMPIAR:
	SBI		PINC, 2
	CLR		R24 //Limpia contador
	RJMP	MOSTRAR	//Regresa a mostrar a puertoB
;---------------------------------------------------------
;Subrutina para inicializar Timer0
INIT_TMR0:
    ;Configurar Timer0: prescaler de 64 para generar un overflow en 10ms
    LDI		R16, (1<<CS01) | (1<<CS00)
    OUT		TCCR0B, R16
    LDI		R16, 100
    OUT		TCNT0, R16
    RET
;Suma 1 al contador de display 7seg
SUMAR:
    LD		R19, Z+
    OUT		PORTD, R19
    RET
;Resta 1 al contador de display 7seg
RESTAR:
    LD		R19, -Z
    OUT		PORTD, R19
    RET
;Si el contador llegó a 16 regresa a 0
REINICIO1:
	LDI		ZL, 0x00
	LDI		ZH,	0x01
	RJMP	LOOP
;Si el contador llegó a menos de 0 regresa a 16
REINICIO2:
	LDI		ZL, 0x0F
	LDI		ZH, 0x01
	RJMP	LOOP


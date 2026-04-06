/*
 * This file is part of Betaflight.
 *
 * Betaflight is free software. You can redistribute this software
 * and/or modify this software under the terms of the GNU General
 * Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later
 * version.
 *
 * Betaflight is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this software.
 *
 * If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#define FC_TARGET_MCU     STM32F405

#define BOARD_NAME        novaX_F405
#define MANUFACTURER_ID   NOVX

#define USE_ACC
#define USE_ACC_SPI_ICM42688P
#define USE_GYRO
#define USE_GYRO_SPI_ICM42688P
#define USE_BARO
#define USE_BARO_SPI_SPL06
#define USE_MAG
#define USE_MAG_QMC5883
#define USE_MAX7456
#define USE_SDCARD

// ---- LEDs ----
#define LED0_PIN             PC13

// ---- Buzzer (active HIGH through NPN transistor) ----
#define BEEPER_PIN           PC15
#define BEEPER_INVERTED

// ---- Motors (8 outputs, M2/M4 bidirectional DShot capable) ----
#define MOTOR1_PIN           PB6
#define MOTOR2_PIN           PB7
#define MOTOR3_PIN           PB0
#define MOTOR4_PIN           PB1
#define MOTOR5_PIN           PC8
#define MOTOR6_PIN           PC9
#define MOTOR7_PIN           PB10
#define MOTOR8_PIN           PA15

// ---- LED Strip ----
#define LED_STRIP_PIN        PA8

// ---- Camera Control ----
#define CAMERA_CONTROL_PIN   PB14

// ---- UARTs ----
// UART1: GPS (MAX-M10S) on P3
#define UART1_TX_PIN         PA9
#define UART1_RX_PIN         PA10
// UART2: Receiver (SBUS/PPM) on P10
#define UART2_TX_PIN         PA2
#define UART2_RX_PIN         PA3
// UART3: VTX on P6
#define UART3_TX_PIN         PC10
#define UART3_RX_PIN         PC11
// UART4: ELRS on P8
#define UART4_TX_PIN         PA0
#define UART4_RX_PIN         PA1
// UART5: ESC Telemetry (RX only)
#define UART5_RX_PIN         PD2
// UART6: Spare
#define UART6_TX_PIN         PC6
#define UART6_RX_PIN         PC7

// ---- PPM/SBUS input ----
#define RX_PPM_PIN           PA3

// ---- SPI ----
// SPI1: IMU (ICM-42688-P)
#define SPI1_SCK_PIN         PA5
#define SPI1_SDI_PIN         PA6
#define SPI1_SDO_PIN         PA7
// SPI2: OSD (AT7456E)
#define SPI2_SCK_PIN         PB13
#define SPI2_SDI_PIN         PC2
#define SPI2_SDO_PIN         PC3
// SPI3: SD Card
#define SPI3_SCK_PIN         PB3
#define SPI3_SDI_PIN         PB4
#define SPI3_SDO_PIN         PB5

// ---- I2C (barometer SPL06 + external compass QMC5883P) ----
#define I2C1_SCL_PIN         PB8
#define I2C1_SDA_PIN         PB9

// ---- SPI CS Pins ----
#define GYRO_1_CS_PIN        PA4
#define MAX7456_SPI_CS_PIN   PB12
#define SDCARD_SPI_CS_PIN    PC14

// ---- IMU Interrupt ----
#define GYRO_1_EXTI_PIN      NONE

// ---- ADC ----
#define ADC_VBAT_PIN         PC0
#define ADC_CURR_PIN         PC1
#define ADC_RSSI_PIN         PC5

// ---- Timer Pin Mapping ----
#define TIMER_PIN_MAPPING \
    TIMER_PIN_MAP( 0, PB6 , 1, 0) \
    TIMER_PIN_MAP( 1, PB7 , 1, 0) \
    TIMER_PIN_MAP( 2, PB0 , 2, 0) \
    TIMER_PIN_MAP( 3, PB1 , 2, 0) \
    TIMER_PIN_MAP( 4, PC8 , 2, 0) \
    TIMER_PIN_MAP( 5, PC9 , 2, 0) \
    TIMER_PIN_MAP( 6, PB10, 1, 0) \
    TIMER_PIN_MAP( 7, PA15, 1, 0) \
    TIMER_PIN_MAP( 8, PA8 , 1, 0)

// ---- DMA ----
#define ADC1_DMA_OPT         1
#define TIMUP3_DMA_OPT       2
#define TIMUP8_DMA_OPT       0

// ---- Sensor Instances ----
#define GYRO_1_SPI_INSTANCE  SPI1
#define GYRO_1_ALIGN         CW270_DEG_FLIP
#define MAX7456_SPI_INSTANCE SPI2
#define BARO_I2C_INSTANCE    I2CDEV_1
#define MAG_I2C_INSTANCE     I2CDEV_1

// ---- SD Card (SPI-based) ----
#define SDCARD_SPI_INSTANCE  SPI3
#define SDCARD_DETECT_PIN    NONE

// ---- Defaults ----
#define DEFAULT_RX_FEATURE       FEATURE_RX_SERIAL
#define SERIALRX_PROVIDER        SERIALRX_CRSF
#define SERIALRX_UART            SERIAL_PORT_UART4
#define DEFAULT_BLACKBOX_DEVICE  BLACKBOX_DEVICE_SDCARD
#define DEFAULT_CURRENT_METER_SOURCE CURRENT_METER_ADC
#define DEFAULT_VOLTAGE_METER_SOURCE VOLTAGE_METER_ADC
#define DEFAULT_CURRENT_METER_SCALE  250

#define ENSURE_MPU_DATA_READY_IS_LOW

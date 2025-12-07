/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body with Switch State Sync
  ******************************************************************************
  */
/* USER CODE END Header */

#include "main.h"

/* USER CODE BEGIN Includes */
#include <stdio.h>
#include <string.h>
/* USER CODE END Includes */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */
uint32_t lastHeartbeatTick = 0;
uint32_t lastSwitchStateTick = 0;
uint8_t lastReportedMode = 255;
#define HEARTBEAT_INTERVAL_MS 1000
#define SWITCH_STATE_INTERVAL_MS 2000
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART2_UART_Init(void);

/* USER CODE BEGIN PFP */
static void sendData(uint8_t data);
static uint8_t ReadDipSwitch(void);
static uint8_t ReadModeSwitch(void);
static void reportSwitchState(uint8_t mode, uint8_t value);
/* USER CODE END PFP */

/* USER CODE BEGIN 0 */

/**
  * @brief  Bit-banged serial sender.
  */
static void sendData(uint8_t data)
{
  for (int i = 3; i >= 0; --i)
  {
    uint8_t bit = (data >> i) & 0x01;
    HAL_GPIO_WritePin(TX_DATALINE_GPIO_Port, TX_DATALINE_Pin,
                      bit ? GPIO_PIN_SET : GPIO_PIN_RESET);
    for (volatile int d = 0; d < 1000; d++) { __NOP(); }
    HAL_GPIO_WritePin(TX_CLKLINE_GPIO_Port, TX_CLKLINE_Pin, GPIO_PIN_SET);
    for (volatile int d = 0; d < 1000; d++) { __NOP(); }
    HAL_GPIO_WritePin(TX_CLKLINE_GPIO_Port, TX_CLKLINE_Pin, GPIO_PIN_RESET);
    for (volatile int d = 0; d < 1000; d++) { __NOP(); }
  }
}

static uint8_t ReadDipSwitch(void)
{
    uint8_t value = 0;
    if (HAL_GPIO_ReadPin(DIP1_GPIO_Port, DIP1_Pin) == GPIO_PIN_RESET) value |= 0x01;
    if (HAL_GPIO_ReadPin(DIP2_GPIO_Port, DIP2_Pin) == GPIO_PIN_RESET) value |= 0x02;
    if (HAL_GPIO_ReadPin(DIP3_GPIO_Port, DIP3_Pin) == GPIO_PIN_RESET) value |= 0x04;
    if (HAL_GPIO_ReadPin(DIP4_GPIO_Port, DIP4_Pin) == GPIO_PIN_RESET) value |= 0x08;
    return value;
}

/**
  * @brief  Read mode switch
  * @retval 0=serial, 1=uart, 2=parallel
  */
static uint8_t ReadModeSwitch(void)
{
    // Implement based on hardware configuration
    return 1;  // Default to uart mode - update based on hardware
}

/**
  * @brief  Report switch state via UART for website sync
  */
static void reportSwitchState(uint8_t mode, uint8_t value)
{
    char msg[32];
    const char* modeStr;
    
    switch(mode) {
        case 0: modeStr = "serial"; break;
        case 1: modeStr = "uart"; break;
        case 2: modeStr = "parallel"; break;
        default: modeStr = "unknown"; break;
    }
    
    int len = snprintf(msg, sizeof(msg), "MODE:%s VAL:%d\r\n", modeStr, value);
    HAL_UART_Transmit(&huart2, (uint8_t*)msg, len, 100);
}

/* USER CODE END 0 */

int main(void)
{
  HAL_Init();
  SystemClock_Config();
  MX_GPIO_Init();
  MX_USART2_UART_Init();

  /* USER CODE BEGIN 2 */
  lastHeartbeatTick = HAL_GetTick();
  lastSwitchStateTick = HAL_GetTick();
  /* USER CODE END 2 */

  while (1)
  {
    /* USER CODE BEGIN 3 */
    
    uint32_t now = HAL_GetTick();
    
    // Periodic heartbeat
    if (now - lastHeartbeatTick >= HEARTBEAT_INTERVAL_MS)
    {
        const char heartbeat[] = "STM32_ALIVE\n";
        HAL_UART_Transmit(&huart2, (uint8_t*)heartbeat, sizeof(heartbeat) - 1, HAL_MAX_DELAY);
        lastHeartbeatTick = now;
    }
    
    // Periodic switch state reporting
    if (now - lastSwitchStateTick >= SWITCH_STATE_INTERVAL_MS)
    {
        uint8_t currentMode = ReadModeSwitch();
        uint8_t currentValue = ReadDipSwitch();
        
        if (currentMode != lastReportedMode)
        {
            reportSwitchState(currentMode, currentValue);
            lastReportedMode = currentMode;
        }
        else
        {
            reportSwitchState(currentMode, currentValue);
        }
        
        lastSwitchStateTick = now;
    }
    
    // Button handler
    if (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
    {
      for (volatile int d = 0; d < 3000; d++) { __NOP(); }

      if (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
      {
        uint8_t dipValue = ReadDipSwitch();
        uint8_t mode = ReadModeSwitch();

        if (mode == 0)  // serial
        {
            sendData(dipValue);
        }
        else if (mode == 1)  // uart
        {
            char msg[16];
            int len = snprintf(msg, sizeof(msg), "VAL:%X\r\n", dipValue & 0x0F);
            HAL_UART_Transmit(&huart2, (uint8_t*)msg, len, 100);
        }
        else if (mode == 2)  // parallel
        {
            sendData(dipValue);
        }
        
        reportSwitchState(mode, dipValue);

        while (HAL_GPIO_ReadPin(TX_BUTTON_GPIO_Port, TX_BUTTON_Pin) == GPIO_PIN_SET)
        {
          for (volatile int d = 0; d < 3000; d++) { __NOP(); }
        }
      }
    }

    /* USER CODE END 3 */
  }
}

void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSI;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;
  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

static void MX_USART2_UART_Init(void)
{
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 38400;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
  huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;

  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
}

static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  __HAL_RCC_GPIOF_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  HAL_GPIO_WritePin(TX_CLKLINE_GPIO_Port, TX_CLKLINE_Pin, GPIO_PIN_RESET);
  HAL_GPIO_WritePin(TX_DATALINE_GPIO_Port, TX_DATALINE_Pin, GPIO_PIN_RESET);

  GPIO_InitStruct.Pin = TX_CLKLINE_Pin|TX_DATALINE_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(TX_CLKLINE_GPIO_Port, &GPIO_InitStruct);

  GPIO_InitStruct.Pin = TX_BUTTON_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(TX_BUTTON_GPIO_Port, &GPIO_InitStruct);

  GPIO_InitStruct.Pin = DIP1_Pin | DIP2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

  GPIO_InitStruct.Pin = DIP3_Pin | DIP4_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLUP;
  HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
}

void Error_Handler(void)
{
  __disable_irq();
  while (1)
  {
  }
}

#ifdef  USE_FULL_ASSERT
void assert_failed(uint8_t *file, uint32_t line)
{
}
#endif /* USE_FULL_ASSERT */


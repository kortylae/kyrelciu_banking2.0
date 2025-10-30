ALTER TABLE `users`
ADD COLUMN `bank_account_number` VARCHAR(50) NULL;

CREATE TABLE IF NOT EXISTS `banking_transactions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `type` ENUM('deposit','withdraw','transfer_in','transfer_out') NOT NULL,
  `amount` DECIMAL(15,2) NOT NULL,
  `target_account` VARCHAR(50) NULL,
  `from_account` VARCHAR(50) NULL,
  `title` VARCHAR(255) DEFAULT '',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

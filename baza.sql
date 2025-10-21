ALTER TABLE `users`
ADD COLUMN `bank_account_number` VARCHAR(50) NULL AFTER `money`,

CREATE TABLE IF NOT EXISTS `banking_transactions` (
  `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(50) NOT NULL,
  `type` VARCHAR(50) NOT NULL,
  `amount` INT NOT NULL,
  `target_account` VARCHAR(50) NULL,
  `from_account` VARCHAR(50) NULL,
  `title` VARCHAR(255) NULL,
  `created_at` DATETIME NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE DATABASE IF NOT EXISTS revisions CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE USER 'revisions'@'%' IDENTIFIED BY 'revisionspassword';
GRANT ALL PRIVILEGES ON revisions.* TO 'revisions'@'%';
FLUSH PRIVILEGES;

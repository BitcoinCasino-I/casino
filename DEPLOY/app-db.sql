CREATE DATABASE IF NOT EXISTS `casinoapp`
  DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
USE casinoapp;

--
-- Table structure for table `user`
--

CREATE TABLE IF NOT EXISTS `user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(30) NOT NULL,
  `email` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `banned` tinyint(1) NOT NULL DEFAULT '0',
  `balance` int NOT NULL DEFAULT '20',
  `activationcode` int DEFAULT NULL,
  `activated` tinyint(1) NOT NULL DEFAULT '0',
  `isadmin` tinyint(1) NOT NULL DEFAULT '0',
  `lastlogin` datetime DEFAULT NULL,
  `lastactive` datetime DEFAULT NULL,
  `profileimg` tinyint(1) NOT NULL DEFAULT '0',
  `profileimgext` varchar(5) DEFAULT NULL,
  PRIMARY KEY  (`id`)
) DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;
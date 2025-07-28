# ベースとなるイメージを指定
FROM php:8.2-apache

# 必要なライブラリとPHP拡張機能をインストール
RUN apt-get update && apt-get install -y \
  git unzip libzip-dev \
  && docker-php-ext-install -j$(nproc) zip pdo_mysql

# Apache設定
COPY ./docker/000-default.conf /etc/apache2/sites-available/000-default.conf
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
RUN a2enmod rewrite

# Composerをインストール
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# 1. 依存関係ファイルのみを先にコピー
COPY composer.json composer.lock ./

# 2. 依存パッケージをインストール
RUN composer install --no-interaction --no-plugins --no-scripts --no-dev --prefer-dist --optimize-autoloader

# 3. アプリケーションの全ファイルをコピー
COPY . .

# 4. 開発環境のキャッシュを物理的に削除
RUN rm -f bootstrap/cache/*.php

# 5. キャッシュクリアコマンドを実行
RUN php artisan config:clear
RUN php artisan route:clear
RUN php artisan view:clear

# 6. 所有権とパーミッションを最後に設定
RUN chown -R www-data:www-data .
RUN chmod -R 775 storage bootstrap/cache

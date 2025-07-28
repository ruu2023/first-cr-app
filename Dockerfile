# ベースとなるイメージを指定
FROM php:8.2-apache

# 必要なライブラリ(git, unzip)とPHP拡張機能(zip, pdo_mysql)をインストール
RUN apt-get update && apt-get install -y \
  git \
  unzip \
  libzip-dev \
  && docker-php-ext-install -j$(nproc) zip pdo_mysql

# Apacheがリッスンするグローバルなポートを8080に変更
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf

# 作成したApache設定ファイルをコンテナにコピーする
COPY ./docker/000-default.conf /etc/apache2/sites-available/000-default.conf

# mod_rewriteを有効化
RUN a2enmod rewrite

# Composerをインストール
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# アプリケーションの依存パッケージをインストール
WORKDIR /var/www/html
COPY . .
RUN composer install --no-interaction --no-plugins --no-scripts --no-dev --prefer-dist --optimize-autoloader

# --- ▼▼▼ ここが重要 ▼▼▼ ---
# 開発環境のキャッシュを物理的に削除する
RUN rm -f bootstrap/cache/*.php

# キャッシュクリアコマンドを実行する (念のため)
RUN php artisan config:clear
RUN php artisan route:clear
RUN php artisan view:clear
# --- ▲▲▲ ここまで ▲▲▲ ---

# ファイル所有権とパーミッションを最後に設定する
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

Собрать образ:

`docker build --build-arg GITHUB_TOKEN=вставить --build-arg SOFTS_PASS=вставить --build-arg PG_PASS=вставить -t medods_old .`

Запустить:

`docker run -v medods_db:/var/lib/postgresql -it  -p 3000:3000 medods_old`

Версия: 3.4

Фиксить: pgp ключи для nodejs, tls сертификаты для rvm
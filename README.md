# Локальный стенд Spark Incidents

Это студенческий стенд курса Spark Incidents. Он поднимает JupyterLab, Spark Master и два Spark Worker. MinIO и History Server подключаются отдельными профилями, когда они нужны уроку.

Внутри нет текстов Stepik, эталонных решений и внутренних авторских проверок. Ноутбуки студент получает во вложениях к урокам и кладёт в `workspace/`.

## Требования

- Docker Desktop с Docker Compose v2;
- предварительный ориентир: 16 ГБ RAM хоста, 8 ГБ для Docker, 4 CPU и 15 ГБ диска;
- свободные локальные порты из `.env.example`.

Стенд проверен 20 сентября 2026 года на Windows с Docker Desktop: 12 доступных
Docker CPU и примерно 7,6 ГиБ RAM. Это проверенная конфигурация одной машины;
минимальные требования и работа на ARM пока не подтверждены. Образы MinIO
закреплены для Linux amd64. Для команд ниже используй PowerShell 7.

## Быстрый старт

В уроке 1.2 на Stepik открой ссылку на этот публичный репозиторий и версию
стенда, указанную в уроке. На странице выпуска GitHub скачай `Source code (zip)`.
Git и аккаунт GitHub для прохождения курса не нужны. Распакуй архив и при желании
переименуй извлечённую папку в `spark_incidents_stand`. Команды ниже выполняй
из папки, где лежит `compose.yaml`, а не из окна просмотра архива.
Не скачивай произвольное состояние `main` вместо указанной версии: файлы стенда
должны совпадать с notebook и примерами урока.
Ноутбуки скачиваются из вложений соответствующих уроков отдельно и кладутся
в `workspace/`. Подробности есть в [работе с файлами](docs/files-and-notebooks.md).

Если Docker ещё не установлен, пройди [установку на Windows](docs/windows-setup.md).
В ней есть проверка Docker Engine, подготовка `.env`, запуск четырёх базовых
контейнеров, вход в Jupyter и smoke check. Когда что-то остановилось, открой
[диагностику по симптомам](docs/troubleshooting.md). Ниже находится короткий
маршрут для машины с уже работающим Docker Desktop и PowerShell 7.

В PowerShell из папки `spark_incidents_stand`:

```powershell
if (-not (Test-Path -LiteralPath .env)) {
    Copy-Item -LiteralPath .env.example -Destination .env
}
.\scripts\start.ps1
```

После запуска доступны:

- JupyterLab: <http://localhost:18888>
- Spark Master UI: <http://localhost:18088>
- Worker 1 UI: <http://localhost:18089>
- Worker 2 UI: <http://localhost:18090>
- Spark UI активного notebook: первый сеанс на <http://localhost:14040>, следующие на портах до `14050`.

Для входа в Jupyter введи `JUPYTER_TOKEN` из `.env`. В примере это `sparkstudent`.
Вставляй только значение в верхнее поле `Password or token` и нажми `Log in`.
Если `.env` отсутствует, при отсутствии переопределений окружения действует
тот же учебный токен по умолчанию. Нижняя форма установки пароля не нужна.
Порты `14040:4040` и `14041:4041` в Docker Desktop ведут в Spark UI.
Для Jupyter нужен `18888:8888`; открой <http://localhost:18888/lab>.
Адрес `127.0.0.1:8888` в логах относится к контейнеру.
Этот учебный токен можно заменить своим. Порты доступны только через localhost.
Контейнеры предназначены для личного локального стенда и работают от root;
размещать такую конфигурацию на общем сервере нельзя без отдельной настройки.

Скачай notebook из урока в `workspace/` и открой его в Jupyter. Работай с одной
SparkSession за раз: она использует оба core учебного кластера. После просмотра
UI выполни `spark.stop()` и заверши kernel. Тогда следующий notebook получит ресурсы.

Первое вложение для запуска, шаг 4 1.2: `01_02_environment_check.ipynb`.
В Jupyter выбери `Python 3 (ipykernel)` и выполняй ячейки сверху вниз.
Начни с `print(2 + 2)`, получи 4, измени выражение и сохрани файл.
В конце выполни готовую диагностику: нужен результат `ENVIRONMENT CHECK: OK`.
Дописывать путь или функцию в этом первом notebook не требуется.
Если файла нет среди вложений урока, сообщи автору; пустой notebook его не заменяет.

Проверка стенда:

```powershell
.\scripts\health.ps1
```

Проверка запускает короткое Spark-приложение и подтверждает подключение двух executors.
До расчёта проверяются страница входа, авторизованный API и HTML JupyterLab.
Это не заменяет открытие интерфейса в браузере.
Также она читает CSV, выполняет shuffle, пишет Parquet и проверяет read-back.
Для полного стенда используй `.\scripts\health.ps1 -Profile all`: дополнительно
проверяются S3A и появление завершённого приложения в History Server.
Перед проверкой заверши активную SparkSession в notebook.

## Профили

Базовый профиль нужен для первых уроков, планов выполнения, shuffle и Spark UI:

```powershell
.\scripts\start.ps1 -Profile core
```

MinIO нужен для уроков про объектное хранилище:

```powershell
.\scripts\start.ps1 -Profile storage
```

History Server нужен для разбора уже завершённых приложений и postmortem:

```powershell
.\scripts\start.ps1 -Profile postmortem
```

Полный стенд:

```powershell
.\scripts\start.ps1 -Profile all
```

History Server после запуска доступен на <http://localhost:18091>, MinIO Console на <http://localhost:19001>.

MinIO предоставляет локальное S3-хранилище. Логин и пароль берутся из
`MINIO_ROOT_USER` и `MINIO_ROOT_PASSWORD` в `.env`; учебные значения:
`sparkstudent` и `sparkstudent123`. Исходные CSV лежат в bucket `spark-lab`,
префикс `source/csv/`. Например:

```python
source = "s3a://spark-lab/source/csv/intro/orders_intro.csv"
orders = spark.read.option("header", True).csv(source)
```

Здесь типы будут строковыми; явную схему ты задашь в уроке. Запись результатов
делай в `s3a://spark-lab/output/<lab_id>/`, чтобы сохранить исходники.
В MinIO Console видны bucket, объекты и результаты записи.

## Публичный runtime-контракт

Ноутбуки курса могут полагаться только на эти значения:

| Ресурс | Значение внутри контейнера |
|---|---|
| Spark Master | `spark://spark-incidents-master:7077` |
| hostname драйвера | `spark-incidents-jupyter` |
| учебные данные | `/data` только для чтения |
| рабочая папка | `/home/jovyan/work` |
| общий путь Driver и Executor для файловых результатов | `/workspace/output/<lab_id>/` |
| event logs | `/spark-events` |
| MinIO | `http://spark-incidents-minio:9000` в профиле `storage` |

CSV лежат в `data/csv`. Результаты и собственные notebook сохраняй в `workspace`.
Для урока 2.7 нужен `data/csv/intro/typed_values.csv`. Если этого файла нет,
проверь версию стенда по ссылке из шага 1.2. Сохрани свои `workspace` и `.env`,
прежде чем переходить на новый выпуск.

## Остановка и сброс

Остановить контейнеры:

```powershell
.\scripts\stop.ps1
```

Удалить также данные MinIO и event logs:

```powershell
.\scripts\stop.ps1 -Volumes
```

Убрать локальные результаты выбранной лабораторной перед повторением:

```powershell
.\scripts\reset-workspace.ps1 -LabId m03_l02 -WhatIf
.\scripts\reset-workspace.ps1 -LabId m03_l02
```

Скрипт переносит `workspace/output/m03_l02` в `workspace/.reset-backups/`.
Notebook и исходные CSV остаются на месте. Для восстановления перенеси архивную
папку обратно в `workspace/output/` под исходным именем, когда этот путь свободен.
Результаты в MinIO эта команда не сбрасывает. Они имеют отдельный префикс опыта.

## Версии и повторная сборка

Поддерживается текущая связка Spark/PySpark 3.5.1 и Python 3.8.10 из базового
образа. Образ Spark и образы MinIO закреплены digest. JAR проверяются по SHA-256,
Python-пакеты устанавливаются из `requirements.lock`; `requirements.txt`
перечисляет прямые зависимости для сопровождения.

Менеджер расширений JupyterLab запускается в режиме `readonly`. Для курса
установка расширений из PyPI через интерфейс не используется. Это также
исключает ошибку старого PyPI-менеджера с аргументом `proxies`; подробности
и обновление старой сборки есть в [диагностике](docs/troubleshooting.md).

Переменные версий в `.env.example` не означают совместимость с произвольным
обновлением Spark. Смена версии требует обновления digest, lock и полного прогона.
Python 3.8 и выбранные версии образов требуют отдельной ревизии перед коммерческим
релизом. Сейчас проверена совместимость существующих уроков с этой связкой.

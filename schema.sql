-- ============================================
-- BookMyShow Problem Solving Case
-- P1: Schema creation + sample data
-- P2: Query for shows on a given date at a given theatre
-- Directly executable on MySQL
-- ============================================

DROP DATABASE IF EXISTS bookmyshow;
CREATE DATABASE bookmyshow;
USE bookmyshow;

-- ---------- P1: Tables ----------

CREATE TABLE Theatre (
    theatre_id   INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(150) NOT NULL,
    address      VARCHAR(255),
    city         VARCHAR(100) NOT NULL,
    state        VARCHAR(100),
    pincode      VARCHAR(10)
);

CREATE TABLE Screen (
    screen_id    INT AUTO_INCREMENT PRIMARY KEY,
    theatre_id   INT NOT NULL,
    screen_name  VARCHAR(50) NOT NULL,
    screen_type  VARCHAR(100),
    total_seats  INT,
    FOREIGN KEY (theatre_id) REFERENCES Theatre(theatre_id),
    UNIQUE KEY uq_screen_per_theatre (theatre_id, screen_name)
);

CREATE TABLE Movie (
    movie_id       INT AUTO_INCREMENT PRIMARY KEY,
    title          VARCHAR(200) NOT NULL,
    duration_mins  INT,
    censor_rating  VARCHAR(5),
    release_date   DATE,
    genre          VARCHAR(100)
);

CREATE TABLE Language (
    language_id    INT AUTO_INCREMENT PRIMARY KEY,
    language_name  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Format (
    format_id    INT AUTO_INCREMENT PRIMARY KEY,
    format_name  VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Shows (
    show_id       INT AUTO_INCREMENT PRIMARY KEY,
    screen_id     INT NOT NULL,
    movie_id      INT NOT NULL,
    language_id   INT NOT NULL,
    format_id     INT NOT NULL,
    show_date     DATE NOT NULL,
    show_time     TIME NOT NULL,
    ticket_price  DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (screen_id) REFERENCES Screen(screen_id),
    FOREIGN KEY (movie_id) REFERENCES Movie(movie_id),
    FOREIGN KEY (language_id) REFERENCES Language(language_id),
    FOREIGN KEY (format_id) REFERENCES Format(format_id),
    UNIQUE KEY uq_screen_slot (screen_id, show_date, show_time)
);

-- ---------- P1: Sample data ----------

INSERT INTO Theatre (name, address, city, state, pincode) VALUES
('PVR: Nexus', 'Nexus Mall', 'Pune', 'Maharashtra', '411001');

INSERT INTO Screen (theatre_id, screen_name, screen_type, total_seats) VALUES
(1, 'Screen 1', '4K Dolby 7.1', 180),
(1, 'Screen 2', 'Playhouse 4K', 120);

INSERT INTO Movie (title, duration_mins, censor_rating, release_date, genre) VALUES
('Dasara', 155, 'UA', '2023-03-30', 'Drama'),
('Kisi Ka Bhai Kisi Ki Jaan', 148, 'UA', '2023-04-21', 'Action'),
('Tu Jhoothi Main Makkaar', 165, 'UA', '2023-03-08', 'Romance'),
('Avatar: The Way of Water', 192, 'UA', '2022-12-16', 'Sci-Fi');

INSERT INTO Language (language_name) VALUES
('Telugu'), ('Hindi'), ('English');

INSERT INTO Format (format_name) VALUES
('2D'), ('3D');

INSERT INTO Shows (screen_id, movie_id, language_id, format_id, show_date, show_time, ticket_price) VALUES
(1, 1, 1, 1, '2026-09-25', '12:15:00', 220.00),
(1, 2, 2, 1, '2026-09-25', '13:00:00', 250.00),
(1, 2, 2, 1, '2026-09-25', '16:10:00', 250.00),
(1, 2, 2, 1, '2026-09-25', '19:20:00', 280.00),
(1, 2, 2, 1, '2026-09-25', '22:30:00', 250.00),
(2, 3, 2, 1, '2026-09-25', '13:15:00', 240.00),
(2, 4, 3, 2, '2026-09-25', '13:20:00', 320.00);

-- ---------- P2: Shows on a given date at a given theatre ----------

SELECT
    t.name          AS theatre_name,
    scr.screen_name,
    scr.screen_type,
    m.title         AS movie_title,
    l.language_name,
    f.format_name,
    s.show_date,
    s.show_time,
    s.ticket_price
FROM Shows s
JOIN Screen   scr ON s.screen_id   = scr.screen_id
JOIN Theatre  t   ON scr.theatre_id = t.theatre_id
JOIN Movie    m   ON s.movie_id    = m.movie_id
JOIN Language l   ON s.language_id = l.language_id
JOIN Format   f   ON s.format_id   = f.format_id
WHERE t.theatre_id = 1                 -- change to the desired theatre_id
  AND s.show_date  = '2026-09-25'      -- change to the desired date
ORDER BY m.title, s.show_time;

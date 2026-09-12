# Problem Solving Case – BookMyShow

## P1: Entities, Attributes, and Table Design

### Scenario recap
For a given **theatre**, the user sees the next 7 **dates**. Picking a date shows all **shows** running that day at that theatre, each show being a specific **movie**, in a specific **language**, in a specific **format** (2D/3D), on a specific **screen**, at a specific **time**.

### Entities and attributes

**1. Theatre** — a physical cinema location
- `theatre_id` (PK)
- `name`
- `address`
- `city`
- `state`
- `pincode`

**2. Screen** — a single auditorium inside a theatre (a theatre has many screens, each with its own tech/tier)
- `screen_id` (PK)
- `theatre_id` (FK → Theatre)
- `screen_name` (e.g. "Screen 1", "Audi 3")
- `screen_type` (e.g. "4K Dolby 7.1", "Playhouse 4K", "IMAX")
- `total_seats`

**3. Movie** — a film that can be screened
- `movie_id` (PK)
- `title`
- `duration_mins`
- `censor_rating` (U / UA / A)
- `release_date`
- `genre`

**4. Language** — the spoken language a print is screened in
- `language_id` (PK)
- `language_name`

**5. Format** — the projection format
- `format_id` (PK)
- `format_name` (2D / 3D / 4DX)

**6. Show** — one scheduled screening; this is the fact table everything else hangs off
- `show_id` (PK)
- `screen_id` (FK → Screen)
- `movie_id` (FK → Movie)
- `language_id` (FK → Language)
- `format_id` (FK → Format)
- `show_date`
- `show_time`
- `ticket_price`
- Natural/candidate key: `(screen_id, show_date, show_time)` — one screen can only run one show at a given date+time.

### Why `theatre_id` is *not* a column on `Show`

This is the key normalization decision in this design. `Screen` already has `theatre_id`, and `screen_id → theatre_id` (a screen belongs to exactly one theatre). If `Show` also stored `theatre_id` directly, that would violate **BCNF**: `screen_id` would be a determinant of a non-key attribute (`theatre_id`) inside `Show`, even though `screen_id` alone is not a candidate key of `Show` (the candidate key needs `screen_id + show_date + show_time`). Storing it would just duplicate data that's already derivable via `Show → Screen → Theatre`, and duplicated theatre_id could go stale independently of the screen's actual theatre. So `Show` only links to `Screen`, and every "shows at theatre X" query joins through `Screen`.

### Normal form check

- **1NF**: Every attribute is atomic. In the raw UI, one movie row shows *multiple* times in one line ("01:00 PM, 04:10 PM, 07:20 PM, 10:30 PM") — that's a repeating group. Normalized, each of those becomes its own row in `Show`.
- **2NF**: All tables use single-column surrogate PKs (`*_id`), so there's no composite key to have a *partial* dependency on. Every non-key attribute depends on the whole key. (For `Show`, even against its natural composite key `screen_id+show_date+show_time`, `ticket_price` depends on all three — a screen's price can differ by date/time.)
- **3NF**: No non-key attribute depends on another non-key attribute. `screen_type` lives only on `Screen`, not repeated on `Show`; `theatre` details live only on `Theatre`, not duplicated on `Screen` beyond the `theatre_id` FK.
- **BCNF**: Every determinant is a candidate key. As explained above, this is exactly why `theatre_id` is excluded from `Show` — including it would create a determinant (`screen_id`) that isn't a candidate key of that table.

---

## SQL — table creation with sample data (MySQL)

```sql
-- ============================================
-- P1: Schema creation
-- ============================================
DROP DATABASE IF EXISTS bookmyshow;
CREATE DATABASE bookmyshow;
USE bookmyshow;

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

-- ============================================
-- Sample data (modeled on the PVR: Nexus screenshot)
-- ============================================
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
(1, 1, 1, 1, '2026-09-25', '12:15:00', 220.00),  -- Dasara, Telugu, 2D
(1, 2, 2, 1, '2026-09-25', '13:00:00', 250.00),  -- Kisi Ka Bhai Kisi Ki Jaan, Hindi, 2D
(1, 2, 2, 1, '2026-09-25', '16:10:00', 250.00),
(1, 2, 2, 1, '2026-09-25', '19:20:00', 280.00),
(1, 2, 2, 1, '2026-09-25', '22:30:00', 250.00),
(2, 3, 2, 1, '2026-09-25', '13:15:00', 240.00),  -- Tu Jhoothi Main Makkaar, Hindi, 2D
(2, 4, 3, 2, '2026-09-25', '13:20:00', 320.00);  -- Avatar: The Way of Water, English, 3D
```

---

## P2: Query — all shows on a given date at a given theatre, with timings

```sql
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
WHERE t.theatre_id = 1                 -- given theatre
  AND s.show_date  = '2026-09-25'      -- given date
ORDER BY m.title, s.show_time;
```

This joins `Shows` up through `Screen` to reach `Theatre` (per the BCNF design above), and out to `Movie`, `Language`, and `Format` to reconstruct exactly the view shown in the app: theatre → date → movie (with language/format tag) → list of show timings.

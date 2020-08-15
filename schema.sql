CREATE TABLE locations (
    id serial PRIMARY KEY,
    name text NOT NULL UNIQUE,
    type text NOT NULL DEFAULT 'town',
    woeid integer NOT NULL DEFAULT 1
);

CREATE TABLE trends (
    id serial PRIMARY KEY,
    name text NOT NULL,
    volume integer NOT NULL DEFAULT 0,
    location_id integer NOT NULL REFERENCES locations (id)
)
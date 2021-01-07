DO $$
DECLARE
  schema_version INTEGER;
BEGIN

  IF NOT EXISTS (
   SELECT FROM information_schema.tables WHERE table_name = 'config'
   ) THEN
    RAISE NOTICE 'no config table. building it';
    CREATE TABLE config (
      id SERIAL PRIMARY KEY,
      config_name TEXT NOT NULL,
      config_value TEXT NOT NULL
    );
    CREATE INDEX configs ON config USING HASH(config_name);
    INSERT INTO config (config_name, config_value) VALUES ('schema_version', '0');
  END IF;

  SELECT config_value INTO schema_version FROM config WHERE config_name = 'schema_version';
  IF schema_version < 1 THEN

    RAISE NOTICE 'upgrading schema to version 1'; 

    -- utility tables
    -- TODO in later versions, we can add more advanced management of extensions and media types (fka mime types)
    CREATE TABLE mediatype (
      id SERIAL PRIMARY KEY,
      type_name text NOT NULL,
      extension VARCHAR(10) NOT NULL -- prefered extension. no need to capture all possible extensions here.
    );
    INSERT INTO mediatype (id, type_name, extension) VALUES (1, 'image/jpeg', 'jpg');

    -- operating environment

    CREATE TABLE camera (
      id SERIAL PRIMARY KEY,
      camera_name VARCHAR(20) NOT NULL,
      descr TEXT
    );

    CREATE TABLE photo (
      id SERIAL PRIMARY KEY,
      camera INTEGER NOT NULL REFERENCES camera,
      mediatype INTEGER NOT NULL REFERENCES mediatype,
      filename TEXT NOT NULL,
      photo_dt DATE NOT NULL
    );

    CREATE TABLE thumbnail_spec (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      spec TEXT NOT NULL,
      descr TEXT NOT NULL
    );
    INSERT INTO thumbnail_spec (name, spec, descr) VALUES 
      ('h100', '{"height":100}', '100px tall thumbnail');

    CREATE TABLE thumbnail (
      id SERIAL PRIMARY KEY,
      photo INTEGER NOT NULL REFERENCES photo,
      spec INTEGER NOT NULL REFERENCES thumbnail_spec,
      filename TEXT NOT NULL
    );

    CREATE TABLE tag (
      id SERIAL PRIMARY KEY,
      tag_name VARCHAR(20) NOT NULL,
      service_tag BOOLEAN NOT NULL DEFAULT FALSE,
      descr TEXT
    );
    CREATE INDEX tags ON tag USING HASH(tag_name);
    INSERT INTO tag (tag_name, service_tag, descr) VALUES ('-schema-v-1', true, 'Image schema version 1');
    INSERT INTO tag (tag_name, service_tag, descr) VALUES ('-camera-v-1', true, 'Camera software version 1');

    CREATE TABLE image_tag (
      id SERIAL PRIMARY KEY,
      photo INTEGER NOT NULL REFERENCES photo,
      tag INTEGER NOT NULL REFERENCES tag,
      -- three-stage logic: true means a human reviewd the photo and decided
      -- it should be tagged, false means a human reviewed it a decided it
      -- should NOT be tagged, and null means a human has never reviewed it
      human_tagged BOOLEAN,
      -- the date the human tagged the image
      human_tagged_dt DATE,
      -- -0.999999 to 0.999999, assigned by machine learning, null if never
      -- tried, negative means the machine is confident the image should NOT
      -- get this tag
      confidence NUMERIC(6,6),
      confirmed BOOLEAN, -- true if accepted, false if rejected, null if never tried
      confidence_dt DATE -- should be null if and only if confidence is null
    );

    -- specifies tags allowed for images from that camera
    CREATE TABLE tag_camera (
      id SERIAL PRIMARY KEY,
      tag INTEGER NOT NULL REFERENCES tag,
      camera INTEGER NOT NULL REFERENCES camera
    );

    UPDATE config SET config_value = 1 WHERE config_name='schema_version';
  END IF;
END
$$;

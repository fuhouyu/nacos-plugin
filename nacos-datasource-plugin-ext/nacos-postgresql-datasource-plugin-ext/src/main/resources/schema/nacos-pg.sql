/*
 * Copyright 1999-2018 Alibaba Group Holding Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/******************************************/
/*   表名称 = config_info                  */
/******************************************/
CREATE TABLE config_info (
                             id bigserial PRIMARY KEY,
                             data_id varchar(255) NOT NULL,
                             group_id varchar(128),
                             content text NOT NULL,
                             md5 varchar(32),
                             gmt_create timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             gmt_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             src_user text,
                             src_ip varchar(50),
                             app_name varchar(128),
                             tenant_id varchar(128) DEFAULT '',
                             c_desc varchar(256),
                             c_use varchar(64),
                             effect varchar(64),
                             type varchar(64),
                             c_schema text,
                             encrypted_data_key varchar(1024)  DEFAULT ''
);

CREATE UNIQUE INDEX uk_configinfo_datagrouptenant ON config_info(data_id, group_id, tenant_id);
COMMENT ON TABLE config_info IS 'config_info';
COMMENT ON COLUMN config_info.id IS 'id';
COMMENT ON COLUMN config_info.data_id IS 'data_id';
-- Add comments for other columns similarly...

/******************************************/
/*   表名称 = config_info_gray             */
/******************************************/
CREATE TABLE config_info_gray (
                                  id bigserial PRIMARY KEY,
                                  data_id varchar(255) NOT NULL,
                                  group_id varchar(128) NOT NULL,
                                  content text NOT NULL,
                                  md5 varchar(32),
                                  src_user text,
                                  src_ip varchar(100),
                                  gmt_create timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  gmt_modified timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  app_name varchar(128),
                                  tenant_id varchar(128) DEFAULT '',
                                  gray_name varchar(128) NOT NULL,
                                  gray_rule text NOT NULL,
                                  encrypted_data_key varchar(256) DEFAULT ''
);

CREATE UNIQUE INDEX uk_configinfogray_datagrouptenantgray ON config_info_gray(data_id, group_id, tenant_id, gray_name);
CREATE INDEX idx_dataid_gmt_modified ON config_info_gray(data_id, gmt_modified);
CREATE INDEX idx_gmt_modified ON config_info_gray(gmt_modified);
COMMENT ON TABLE config_info_gray IS 'config_info_gray';

/******************************************/
/*   表名称 = config_tags_relation         */
/******************************************/
CREATE TABLE config_tags_relation (
                                      id bigint NOT NULL,
                                      tag_name varchar(128) NOT NULL,
                                      tag_type varchar(64),
                                      data_id varchar(255) NOT NULL,
                                      group_id varchar(128) NOT NULL,
                                      tenant_id varchar(128) DEFAULT '',
                                      nid bigserial PRIMARY KEY
);

CREATE UNIQUE INDEX uk_configtagrelation_configidtag ON config_tags_relation(id, tag_name, tag_type);
CREATE INDEX idx_tenant_id ON config_tags_relation(tenant_id);
COMMENT ON TABLE config_tags_relation IS 'config_tag_relation';

/******************************************/
/*   表名称 = group_capacity               */
/******************************************/
CREATE TABLE group_capacity (
                                id bigserial PRIMARY KEY,
                                group_id varchar(128) NOT NULL DEFAULT '',
                                quota int NOT NULL DEFAULT 0,
                                usage int NOT NULL DEFAULT 0,
                                max_size int NOT NULL DEFAULT 0,
                                max_aggr_count int NOT NULL DEFAULT 0,
                                max_aggr_size int NOT NULL DEFAULT 0,
                                max_history_count int NOT NULL DEFAULT 0,
                                gmt_create timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                gmt_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX uk_group_id ON group_capacity(group_id);
COMMENT ON TABLE group_capacity IS '集群、各Group容量信息表';

/******************************************/
/*   表名称 = his_config_info              */
/******************************************/
CREATE TABLE his_config_info (
                                 id bigint NOT NULL,
                                 nid bigserial PRIMARY KEY,
                                 data_id varchar(255) NOT NULL,
                                 group_id varchar(128) NOT NULL,
                                 app_name varchar(128),
                                 content text NOT NULL,
                                 md5 varchar(32),
                                 gmt_create timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 gmt_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 src_user text,
                                 src_ip varchar(50),
                                 op_type varchar(10),
                                 tenant_id varchar(128) DEFAULT '',
                                 encrypted_data_key varchar(1024) NOT NULL DEFAULT '',
                                 publish_type varchar(50) DEFAULT 'formal',
                                 gray_name varchar(50) DEFAULT NULL,
                                 ext_info text DEFAULT NULL
);

CREATE INDEX idx_gmt_create ON his_config_info(gmt_create);
CREATE INDEX idx_gmt_modified ON his_config_info(gmt_modified);
CREATE INDEX idx_did ON his_config_info(data_id);
COMMENT ON TABLE his_config_info IS '多租户改造';

/******************************************/
/*   表名称 = tenant_capacity              */
/******************************************/
CREATE TABLE tenant_capacity (
                                 id bigserial PRIMARY KEY,
                                 tenant_id varchar(128) NOT NULL DEFAULT '',
                                 quota int NOT NULL DEFAULT 0,
                                 usage int NOT NULL DEFAULT 0,
                                 max_size int NOT NULL DEFAULT 0,
                                 max_aggr_count int NOT NULL DEFAULT 0,
                                 max_aggr_size int NOT NULL DEFAULT 0,
                                 max_history_count int NOT NULL DEFAULT 0,
                                 gmt_create timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 gmt_modified timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX uk_tenant_id ON tenant_capacity(tenant_id);
COMMENT ON TABLE tenant_capacity IS '租户容量信息表';

/******************************************/
/*   表名称 = tenant_info                  */
/******************************************/
CREATE TABLE tenant_info (
                             id bigserial PRIMARY KEY,
                             kp varchar(128) NOT NULL,
                             tenant_id varchar(128) DEFAULT '',
                             tenant_name varchar(128) DEFAULT '',
                             tenant_desc varchar(256),
                             create_source varchar(32),
                             gmt_create bigint NOT NULL,
                             gmt_modified bigint NOT NULL
);

CREATE UNIQUE INDEX uk_tenant_info_kptenantid ON tenant_info(kp, tenant_id);
CREATE INDEX idx_tenant_id ON tenant_info(tenant_id);
COMMENT ON TABLE tenant_info IS 'tenant_info';

/******************************************/
/*   表名称 = users                        */
/******************************************/
CREATE TABLE users (
                       username varchar(50) PRIMARY KEY,
                       password varchar(500) NOT NULL,
                       enabled boolean NOT NULL
);
COMMENT ON COLUMN users.username IS 'username';
COMMENT ON COLUMN users.password IS 'password';
COMMENT ON COLUMN users.enabled IS 'enabled';

/******************************************/
/*   表名称 = roles                        */
/******************************************/
CREATE TABLE roles (
                       username varchar(50) NOT NULL,
                       role varchar(50) NOT NULL,
                       PRIMARY KEY (username, role)
);
COMMENT ON COLUMN roles.username IS 'username';
COMMENT ON COLUMN roles.role IS 'role';

/******************************************/
/*   表名称 = permissions                 */
/******************************************/
CREATE TABLE permissions (
                             role varchar(50) NOT NULL,
                             resource varchar(128) NOT NULL,
                             action varchar(8) NOT NULL,
                             PRIMARY KEY (role, resource, action)
);
COMMENT ON COLUMN permissions.role IS 'role';
COMMENT ON COLUMN permissions.resource IS 'resource';
COMMENT ON COLUMN permissions.action IS 'action';
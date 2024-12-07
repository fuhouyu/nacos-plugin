/*
 * Copyright 2024-2024 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.alibaba.nacos.plugin.datasource.impl.base;

import com.alibaba.nacos.plugin.datasource.dialect.DatabaseDialect;
import com.alibaba.nacos.plugin.datasource.manager.DatabaseDialectManager;

/**
 * <p>
 * base datasource page
 * </p>
 *
 * @author fuhouyu
 * @since 2024/12/7 12:06
 */
public interface BaseDatasourcePage {

    String getDataSource();

    default DatabaseDialect getDatabaseDialect() {
        return DatabaseDialectManager.getInstance().getDialect(getDataSource());
    }

    default String getLimitPageSqlWithOffset(String sql, int startRow, int pageSize) {
        return getDatabaseDialect().getLimitPageSqlWithOffset(sql, startRow, pageSize);
    }
}

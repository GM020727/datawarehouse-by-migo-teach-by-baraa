##  Gold 层数据字典

### 说明

Gold 层为业务级数据模型，服务于分析和报表需求，包含维度表与事实表，聚焦核心业务指标。

### 1.gold.dim_customers

- **用途：**存储客户详细信息，并扩充人口统计与地理数据。
- **列：**

|   Column Name   |  Data Type   |                         Description                          |
| :-------------: | :----------: | :----------------------------------------------------------: |
|  customer_key   |     INT      | Surrogate key uniquely identifying each customer record in the dimension table.<br />用于唯一标识维度表中每个客户记录的代理键。 |
|   customer_id   |     INT      | Unique numerical identifier assigned to each customer.<br />分配给每位客户的唯一数字标识符。 |
| customer_number | NVARCHAR(50) | Alphanumeric identifier representing the customer, used for tracking and referencing.<br />代表客户的字母数字标识符，用于追踪和引用。 |
|   first_name    | NVARCHAR(50) | The customer's first name, as recorded in the system.<br />客户的名字，按系统记录填写。 |
|    last_name    | NVARCHAR(50) | The customer's last name or family name.<br />客户的姓氏或家族名。 |
|     country     | NVARCHAR(50) | The country of residence for the customer (e.g., 'Australia').<br />客户居住国家(例如'Australia')。 |
| marital_status  | NVARCHAR(50) | The marital status of the customer (e.g., 'Married', 'Single').<br />客户的婚姻状况(例如，“已婚”，“单身”)。 |
|     gender      | NVARCHAR(50) | The gender of the customer (e.g., 'Male', 'Female', 'n/a').<br />客户的性别(例如，“Male”、"Female"、 "n/a")。 |
|    birthdate    |     DATE     | The date of birth of the customer, formatted as YYYY-MM-DD (e.g., 1971-10-06).<br />客户的出生日期，格式为YYYY-MM-DD(例如，1971-10-06)。 |
|   create_dat    |     DATE     | The date and time when the customer record was created in the system<br />客户记录在系统中创建的日期和时间: |

------

### 2.gold.dim_products

- **用途**：提供产品及其属性的相关信息。
- **Columns:**

|     Column Name      |  Data Type   |                         Description                          |
| :------------------: | :----------: | :----------------------------------------------------------: |
|     product_key      |     INT      | Surrogate key uniquely identifying each product record in the product dimension table.<br />代理键，用于唯一标识产品维度表中的每个产品记录。 |
|      product_id      |     INT      | A unique identifier assigned to the product for internal tracking and referencing.<br />分配给产品的唯一标识符，用于内部追踪和引用。 |
|    product_number    | NVARCHAR(50) | A structured alphanumeric code representing the product, often used for categorization or inventory.<br />代表产品的结构化字母数字编码，常用于分类或库存管理。 |
|     product_name     | NVARCHAR(50) | Descriptive name of the product, including key details such as type, color, and size.<br />产品的描述性名称，包括类型、颜色和尺寸等关键细节。 |
|     category_id      | NVARCHAR(50) | A unique identifier for the product's category, linking to its high-level classification.<br />产品类别的唯一标识符，链接至其高层分类。 |
|       category       | NVARCHAR(50) | The broader classification of the product (e.g., Bikes, Components) to group related items<br />产品的更广泛分类(例如，自行车、组件)，用于归类相关项目。 |
|     subcategory      | NVARCHAR(50) | A more detailed classification of the product within the category, such as product type.<br />在类别内的更详细的产品分类，例如产品类型。 |
| maintenance_required | NVARCHAR(50) | Indicates whether the product requires maintenance (e.g., 'Yes', 'No').<br />表示产品是否需要维护(例如，“是”、“否”)。 |
|         cost         |     INT      | The cost or base price of the product, measured in monetary units.<br />产品的成本或基础价格，以货币单位衡量。 |
|     product_line     | NVARCHAR(50) | The specific product line or series to which the product belongs (e.g., Road, Mountain).<br />产品所属的具体产品线或系列(例如:公路、山地)。 |
|      start_date      |     DATE     | The date when the product became available for sale or use, stored in<br />产品可销售或使用的日期，存储于 |

------

### 3.gold.fact_sales

-  **Purpose:** Stores transactional sales data for analytical purposes
- **Columns:**

|  Column Name  |  Data Type   |                         Description                          |
| :-----------: | :----------: | :----------------------------------------------------------: |
| order_number  | NVARCHAR(50) | A unique alphanumeric identifier for each sales order (e.g., 'SO54496')<br />每个销售订单的唯一字母数字标识符(例如，"S054496”) |
|  product_key  |     INT      | Surrogate key linking the order to the product dimension table.<br />将订单与产品维度表关联的代理键。 |
| customer_key  |     INT      | Surrogate key linking the order to the customer dimension table.<br />将订单与客户维度表关联的代理键。 |
|  order_date   |     DATE     |     The date when the order was placed.<br />下单日期。      |
| shipping_date |     DATE     | The date when the order was shipped to the customer.<br />订单发货给客户的日期。 |
|   due_date    |     DATE     | The date when the order payment was due.<br />订单付款到期日。 |
| sales_amount  |     INT      | The total monetary value of the sale for the line item, in whole currency units (e.g. 25)<br />该行项目产品的单价，以整数货币单位表示(例如，25). |
|   quantity    |     INT      | The number of units of the product ordered for the line item (e.g., 1).<br />该行项目订购的产品单位数量(例如，1)。 |
|     price     |     INT      | he price per unit of the product for the line item, in whole currency units (e.g., 25).<br />该行项目销售的总货币价值，以整数货币单位表示(例如:25) |
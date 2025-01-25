---

#### **e. `developer_guides/api_reference.md`**
```markdown
# API Reference

## Endpoints
### **POST /ingest**
- **Description:** Ingest data from IFIX.
- **Request Body:** JSON object with `timestamp` and `value`.
- **Response:** JSON object with `message`.

### **POST /predict**
- **Description:** Get predictions for meter data.
- **Request Body:** JSON object with `values`.
- **Response:** JSON object with `prediction`.
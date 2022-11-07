*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.FileSystem
Library    OperatingSystem
Library    RPA.Tables
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    Screenshot
Library    RPA.Robocorp.Vault


*** Tasks ***
Minimal tasks
    Open a browser
    ${orders}=    Get orders url
    FOR    ${row}    IN    @{orders}
        Log To Console    ${row}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit form
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Delete screenshots and receipts
    Close the browser
        
    

*** Keywords ***
Read the orders file
    [Documentation]    for test purposes
    ${table}=    Read table from CSV    orders.csv    dialect=excel
    Log To Console   Found columns: ${table.columns}   
    

Open a browser
    Open Available Browser    https://robotsparebinindustries.com/#/
    Wait Until Element Is Visible    id:root
    Click Element    //a[text()='Order your robot!']

Close the annoying modal
    Wait Until Element Is Enabled    //button[@class='btn btn-dark']
    Click Button    //button[text()='OK']

Get orders url
    ${orders_file_url}=    Get Secret    cert2address
    RPA.HTTP.Download   ${orders_file_url}[value]   overwrite=True  
    ${orders}=    Read table from CSV    ${path}
    RETURN    ${orders}

Fill the form
    [Arguments]    ${row}
    # Click Button    //button[text()='Show model info']
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    //input[@id='address']    ${row}[Address]


Preview the robot
    Click Button When Visible    id:preview


Submit form
    Wait Until Element Is Visible    //div[@id='robot-preview-image']
    Wait Until Keyword Succeeds    5x    0.5sec    Click the button Submit  

Click the button Submit
    Click Button When Visible    id:order
    Page Should Not Contain Element    //div[@class='alert alert-danger']

Store the receipt as a PDF file
    [Arguments]    ${row}
    Set Local Variable     ${pdf_path}    ${orders_path}${/}${row}.PDF
    Wait Until Element Is Visible    id:receipt
    ${data}=    Get Element Attribute    id:receipt    outerHTML
    HTML To PDF    ${data}    ${pdf_path}
    [Return]    ${pdf_path}    


Take a screenshot of the robot
    [Arguments]    ${row}
    Set Local Variable     ${screenshot_path}    ${screenshots_path}${/}image${row}.PNG
    Wait Until Element Is Visible    //div[@id='robot-preview-image']    
    Screenshot   //div[@id='robot-preview-image']    ${screenshot_path}       
    [Return]    ${screenshot_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    # Open Pdf    ${pdf}    
    ${screenshot_list}=    Create list    ${screenshot}:align=center
    Add Files To Pdf    ${screenshot_list}    ${pdf}    append=True

Go to order another robot
    Click Button When Visible    id:order-another

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}${/}PDFs.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders    ${zip_file_name}

Close the browser
    Close Browser

Delete screenshots and receipts
    Empty Directory    ${orders_path}
    Empty Directory    ${screenshots_path}
   
*** Variables ***
${path}=    ${CURDIR}${/}orders.csv
${orders_path}=    ${OUTPUT_DIR}${/}orders
${screenshots_path}=    ${OUTPUT_DIR}${/}screenshots
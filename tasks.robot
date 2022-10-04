*** Settings ***
Documentation       Robot to fill the orders and do tasks related to the process.

Library             RPA.Tables
Library             RPA.JSON
Library             RPA.HTTP
Library             RPA.FileSystem
Library             RPA.Browser.Selenium
Library             RPA.PDF


*** Variables ***
${orderFileUrl}=                https://robotsparebinindustries.com/orders.csv
${orderFileRename}=             robot_order_list.csv
${orderRobotsUrl}=              https://robotsparebinindustries.com/#/robot-order
${screenshotsFolderPath}=       screenshots
${orderReceiptsFolderPath}=     receipts


*** Tasks ***
Submit
    Download, rename and read the CSV order file


*** Keywords ***
Download, rename and read the CSV order file
    Download    ${orderFileUrl}
    Move File    orders.csv    ${orderFileRename}    Overwrite=True
    ${order}=    Read table from CSV    ${orderFileRename}
    Open Available Browser
    Go To    ${orderRobotsUrl}
    Create Directory    ${screenshotsFolderPath}
    Create Directory    ${orderReceiptsFolderPath}
    FOR    ${robot}    IN    @{order}
        Fill the form with needed data    ${robot}
    END

Fill the form with needed data
    [Arguments]    ${value}
    ${robot_id}=    Get value from JSON    ${value}    'Order number'
    ${robot_head}=    Get value from JSON    ${value}    Head
    ${robot_body}=    Get value from JSON    ${value}    Body
    ${robot_legs}=    Get value from JSON    ${value}    Legs
    ${robot_address}=    Get value from JSON    ${value}    Address

    Click Element When Visible    //button[@class="btn btn-dark"]
    Select From List By Value    //select[@id="head"]    ${robot_head}
    Click Element When Visible    //*[@class="form-group"]/div/div[${robot_body}]/label[@for="id-body-${robot_body}"]
    Input Text    //*[@class="form-group"][3]/input    ${robot_legs}
    Input Text    //*[@id="address"]    ${robot_address}
    Click Element When Visible    //button[@id="preview"]
    Sleep    0.5s
    Take screenshot from ordered robot    ${robot_id}
    Click Element When Visible    id:order
    ${checkForWarnings}=    Is Element Visible    //*[@class="alert alert-danger"]
    IF    ${checkForWarnings} == True    Click Element When Visible    id:order
    Make order receipt as PDF    ${robot_id}

Take screenshot from ordered robot
    [Arguments]    ${robot_id}
    Screenshot    //*[@id="robot-preview-image"]    ${screenshotsFolderPath}${/}robot-${robot_id}.png

Make order receipt as PDF
    [Arguments]    ${robot_id}
    Wait Until Element Is Visible    id:receipt
    ${get_order_receipt_element}=    Get Element Attribute    id:receipt    innerHTML
    Html To Pdf
    ...    <div width="100%">${get_order_receipt_element}<br /><div align="center"><img src="${screenshotsFolderPath}${/}robot-${robot_id}.png" /></div></div>
    ...    ${orderReceiptsFolderPath}${/}robot-order-${robot_id}.pdf
    ...    Overwrite=True
    # ${file}=    Create List    ${screenshotsFolderPath}${/}robot-${robot_id}.png:align=center,format=A5
    # Add Files To Pdf
    # ...    ${file}
    # ...    ${orderReceiptsFolderPath}${/}robot-order-${robot_id}.pdf
    # ...    append=True

Save HTML receipt as PDF

Close browser and remove order file
    Close Browser
    Remove File    ${orderFileRename}

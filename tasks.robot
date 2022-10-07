*** Settings ***
Documentation       Robot to fill the orders and do tasks related to the process.

Library             RPA.Tables
Library             RPA.JSON
Library             RPA.HTTP
Library             RPA.FileSystem
Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.Robocloud.Secrets
Library             RPA.Archive
Library             RPA.Dialogs
Library             String

Suite Teardown      Boolean dialog


*** Variables ***
${orderFileRename}              robot_order_list.csv
${orderRobotsUrl}               https://robotsparebinindustries.com/#/robot-order
${screenshotsFolderPath}        screenshots
${orderReceiptsFolderPath}      receipts
${zipNameForReceipts}           all_receipts.zip


*** Tasks ***
Robot to fill the orders, handle errors and do tasks related to the process
    Download, rename and read the CSV order file
    Create a ZIP archive of the PDF receipts


*** Keywords ***
Download, rename and read the CSV order file
    ${env}=    Get Secret    mlar
    Download    ${env}[FILE_URL]
    Move File    orders.csv    ${orderFileRename}    Overwrite=True
    ${order}=    Read table from CSV    ${orderFileRename}
    Open Available Browser
    Go To    ${orderRobotsUrl}
    Create Directory    ${screenshotsFolderPath}
    Create Directory    ${orderReceiptsFolderPath}
    ${index}=    Set Variable    ${0}
    FOR    ${robot}    IN    @{order}
        IF    ${index} == ${0}
            ${userInput}=    User input
            Wait all dialogs
        END
        Set user color variable    ${userInput}
        Fill the form with needed data    ${robot}    ${index}
        ${index}=    Evaluate    ${index} + 1
    END

Fill the form with needed data
    [Arguments]    ${value}    ${index}
    ${robot_id}=    Get value from JSON    ${value}    'Order number'
    ${robot_head}=    Get value from JSON    ${value}    Head
    ${robot_body}=    Get value from JSON    ${value}    Body
    ${robot_legs}=    Get value from JSON    ${value}    Legs
    ${robot_address}=    Get value from JSON    ${value}    Address
    Select From List By Value    //select[@id="head"]    ${robot_head}
    Click Element When Visible    //*[@class="form-group"]/div/div[${robot_body}]/label[@for="id-body-${robot_body}"]
    Input Text    //*[@class="form-group"][3]/input    ${robot_legs}
    Input Text    //*[@id="address"]    ${robot_address}
    Click Element When Visible    //button[@id="preview"]
    Take screenshot from ordered robot    ${robot_id}
    Click Element If Visible    id:order
    ${checkForWarnings}=    Is Element Visible    //*[@class="alert alert-danger"]
    IF    ${checkForWarnings} == True
        FOR    ${x}    IN RANGE    10
            Click Element If Visible    id:order
            IF    ${checkForWarnings} == False    BREAK
        END
    END
    Make order receipt as PDF    ${robot_id}
    Click Element When Visible    id:order-another

Take screenshot from ordered robot
    [Arguments]    ${robot_id}
    Screenshot    //*[@id="robot-preview-image"]    ${screenshotsFolderPath}${/}robot-${robot_id}.png

CompareValues
    [Arguments]    ${stringToCheck}    ${stringToMatch}
    ${toLowerCaseStringToCheck}=    Convert To Lower Case    ${stringToCheck}
    ${toLowerCaseStringToMatch}=    Convert To Lower Case    ${stringToMatch}
    RETURN    Should Be Equal As Strings    ${toLowerCaseStringToCheck}    ${toLowerCaseStringToMatch}    msg=${toLowerCaseStringToMatch}

User input
    Add text input    value    label=Add button which u want to press (Gray, Yellow, Red)
    ${response}=    Run dialog
    ${userValue}=    Convert To Lower Case    ${response.value}
    RETURN    ${userValue}

Set user color variable
    [Arguments]    ${userColor}
    ${varColor}=    Set Variable    ${userColor}
    WHILE    True    limit=3
        IF    "${varColor}" == "gray"
            Click Element When Visible    //*[@class="btn btn-dark"]
            BREAK
        END
        IF    "${varColor}" == "yellow"
            Click Element When Visible    //button[@class="btn btn-warning"]
            BREAK
        END
        IF    "${varColor}" == "red"
            Click Element When Visible    //button[@class="btn btn-danger"]
            BREAK
        END
    END

Make order receipt as PDF
    [Arguments]    ${robot_id}
    Wait Until Element Is Visible    id:receipt
    ${get_order_receipt_element}=    Get Element Attribute    id:receipt    innerHTML
    Html To Pdf
    ...    <div width="100%">${get_order_receipt_element}<br /><div align="center"><img src="${screenshotsFolderPath}${/}robot-${robot_id}.png" /></div></div>
    ...    ${orderReceiptsFolderPath}${/}robot-order-${robot_id}.pdf
    ...    Overwrite=True

Create a ZIP archive of the PDF receipts
    Archive Folder With Zip    receipts    ${zipNameForReceipts}    recursive=True

Open new browser window and go to error report
    # TODO: Gotta fix this later and think other solution
    # Open Browser
    # ${GetPath}=    Absolute Path    output/log.html
    # Go To    ${/}${GetPath}

Boolean dialog
    Add heading    Do you want to erase the files created by the robot (including logs)?
    Add text    Pressing Yes will erase the files. Will give you error, in the end but this can be ignore.
    # TODO: Fix this option later
    # ...    Pressing No will open robot's log file in browser window.
    Add icon    Warning
    Add submit buttons    buttons=Yes,No    default=Yes
    ${return}=    Run dialog
    IF    $return.submit == "Yes"
        Close browser and remove files created by robot
    END
    IF    $return.submit == "No"    Log    Do nothing

Close browser and remove files created by robot
    Close Browser
    Empty directory    ${screenshotsFolderPath}
    Empty directory    ${orderReceiptsFolderPath}
    Empty directory    output
    Remove Files
    ...    ${orderFileRename}
    ...    interactive_console_output.xml
    ...    ${zipNameForReceipts}

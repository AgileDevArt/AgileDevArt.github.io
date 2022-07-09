###################
# Winforms
###################
$Form = New-Object System.Windows.Forms.Form
$Form.ClientSize = New-Object System.Drawing.Size(800,450)
$Form.MinimumSize = New-Object System.Drawing.Size(500,400)

$colImage = New-Object System.Windows.Forms.DataGridViewImageColumn
$colImage.Name = "colImage"
$colImage.HeaderText = "Img"
$colImage.DataPropertyName = "Image"
$colImage.ImageLayout = [System.Windows.Forms.DataGridViewImageCellLayout]::Zoom
$colImage.Width = 40

$colName = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colName.Name = "colName"
$colName.HeaderText = "Name"
$colName.DataPropertyName = "Name"
$colName.Width = 200

$colRank = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colRank.Name = "colRank"
$colRank.HeaderText = "Rank"
$colRank.DataPropertyName = "Rank"
$colRank.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::AllCells
$colRank.DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleCenter

$colPrice = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colPrice.Name = "colPrice"
$colPrice.HeaderText = "Price ($)"
$colPrice.DataPropertyName = "Price"
$colPrice.Width = 100
$colPrice.DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleRight

$colMarketCap = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colMarketCap.Name = "colMarketCap"
$colMarketCap.HeaderText = "Market Cap. ($)"
$colMarketCap.DataPropertyName = "MarketCap"
$colMarketCap.Width = 150
$colMarketCap.DefaultCellStyle.Format = "#,###."
$colMarketCap.DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleRight

$colCircSupply = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$colCircSupply.Name = "colCircSupply"
$colCircSupply.HeaderText = "Circ. Supply"
$colCircSupply.DataPropertyName = "CircSupply"
$colCircSupply.Width = 150
$colCircSupply.DefaultCellStyle.Format = "#,###."
$colCircSupply.DefaultCellStyle.Alignment = [System.Windows.Forms.DataGridViewContentAlignment]::MiddleRight

$coinGrid = New-Object System.Windows.Forms.DataGridView
$coinGrid.AllowUserToAddRows = $False;
$coinGrid.AllowUserToDeleteRows = $False;
$coinGrid.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$coinGrid.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
$coinGrid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::Beige
$coinGrid.Location = New-Object System.Drawing.Point(12, 68)
$coinGrid.Size = New-Object System.Drawing.Size(776, 370)
$coinGrid.RowTemplate.Height = 30
$coinGrid.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$coinGrid.Name = "coinGrid"
$coinGrid.Columns.AddRange( $colImage, $colName, $colRank, $colPrice, $colMarketCap, $colCircSupply )
        
$pbImage = New-Object System.Windows.Forms.PictureBox
$pbImage.Image = New-Object System.Drawing.Bitmap((New-Object System.Net.WebClient).OpenRead("https://agiledevart.github.io/graph.jpg"))
$pbImage.Name = "pbImage"
$pbImage.Size = New-Object System.Drawing.Size(50, 50)
$pbImage.Location = New-Object System.Drawing.Point(12, 12)
$pbImage.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.AutoSize = $True
$lblTitle.Name = "lblTitle"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 25, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::Black
$lblTitle.Location = New-Object System.Drawing.Point(68, 14)
$lblTitle.Size = New-Object System.Drawing.Size(233, 46)
$lblTitle.Text = "Coin Browser"

$lblPage = New-Object System.Windows.Forms.Label
$lblPage.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$lblPage.AutoSize = $True
$lblPage.Name = "lblPage"
$lblPage.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblPage.Location = New-Object System.Drawing.Point(676, 12)
$lblPage.Size = New-Object System.Drawing.Size(53, 28)
$lblPage.Text = "Page: 1"

$btnPrev = New-Object System.Windows.Forms.Button
$btnPrev.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnPrev.Name = "btnPrev"
$btnPrev.Location = New-Object System.Drawing.Point(617, 34)
$btnPrev.Size = New-Object System.Drawing.Size(53, 28)
$btnPrev.Text = "Prev."

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnNext.Name = "btnNext"
$btnNext.Location = New-Object System.Drawing.Point(676, 34)
$btnNext.Size = New-Object System.Drawing.Size(53, 28)
$btnNext.Text = "Next"

$btnAbout = New-Object System.Windows.Forms.Button
$btnAbout.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnAbout.Name = "btnAbout"
$btnAbout.Location = New-Object System.Drawing.Point(735, 34)
$btnAbout.Size = New-Object System.Drawing.Size(53, 28)
$btnAbout.Text = "About"

$Form.Controls.Add($coinGrid)
$Form.Controls.Add($pbImage)
$Form.Controls.Add($lblTitle)
$Form.Controls.Add($lblPage)
$Form.Controls.Add($btnPrev)
$Form.Controls.Add($btnNext)
$Form.Controls.Add($btnAbout)